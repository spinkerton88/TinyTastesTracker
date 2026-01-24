//
//  RecipeOCRService.swift
//  TinyTastesTracker
//
//  Extracts recipe information from images using Vision OCR and AI parsing
//

import UIKit
import Vision

enum RecipeOCRError: LocalizedError {
    case noTextFound
    case parsingFailed
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            return "No text was found in the image. Please try a clearer photo."
        case .parsingFailed:
            return "Failed to parse recipe from the extracted text."
        case .imageProcessingFailed:
            return "Failed to process the image."
        }
    }
}

struct ExtractedRecipe {
    let title: String
    let ingredients: String
    let instructions: String
}

class RecipeOCRService {

    /// Extract text from image using Vision framework
    /// - Parameter image: The image containing recipe text
    /// - Returns: Extracted text from the image
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw RecipeOCRError.imageProcessingFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: RecipeOCRError.noTextFound)
                    return
                }

                // Combine all recognized text with proper line breaks
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                if recognizedText.isEmpty {
                    continuation.resume(throwing: RecipeOCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }

            // Configure for best accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Parse extracted text into recipe components using AI
    /// - Parameters:
    ///   - text: The extracted text from OCR
    ///   - geminiService: The Gemini service for AI parsing
    /// - Returns: Structured recipe data
    func parseRecipe(from text: String, using geminiService: GeminiService) async throws -> ExtractedRecipe {
        let prompt = """
        I have extracted the following text from a recipe image using OCR. Please parse it into a structured recipe format.

        Extract:
        1. Recipe title (if present)
        2. List of ingredients (one per line)
        3. Cooking instructions/steps (numbered if possible)

        OCR Text:
        \(text)

        Please format your response EXACTLY as follows:
        TITLE: [recipe title or "Untitled Recipe" if not found]

        INGREDIENTS:
        - [ingredient 1]
        - [ingredient 2]
        (etc.)

        INSTRUCTIONS:
        1. [step 1]
        2. [step 2]
        (etc.)
        """

        let response = try await geminiService.generateText(prompt: prompt)

        // Parse the AI response
        return try parseAIResponse(response)
    }

    /// Parse the AI-formatted response into structured data
    private func parseAIResponse(_ response: String) throws -> ExtractedRecipe {
        var title = "Untitled Recipe"
        var ingredients = ""
        var instructions = ""

        // Split response into sections
        let lines = response.components(separatedBy: .newlines)
        var currentSection: String?
        var ingredientLines: [String] = []
        var instructionLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("TITLE:") {
                title = trimmed.replacingOccurrences(of: "TITLE:", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = nil
            } else if trimmed == "INGREDIENTS:" {
                currentSection = "ingredients"
            } else if trimmed == "INSTRUCTIONS:" {
                currentSection = "instructions"
            } else if !trimmed.isEmpty {
                if currentSection == "ingredients" {
                    ingredientLines.append(trimmed)
                } else if currentSection == "instructions" {
                    instructionLines.append(trimmed)
                }
            }
        }

        ingredients = ingredientLines.joined(separator: "\n")
        instructions = instructionLines.joined(separator: "\n")

        // Validate we have at least some content
        guard !ingredients.isEmpty || !instructions.isEmpty else {
            throw RecipeOCRError.parsingFailed
        }

        return ExtractedRecipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions
        )
    }

    /// Complete recipe scanning workflow
    /// - Parameters:
    ///   - image: The image containing the recipe
    ///   - geminiService: The Gemini service for AI parsing
    /// - Returns: Structured recipe data
    func scanRecipe(from image: UIImage, using geminiService: GeminiService) async throws -> ExtractedRecipe {
        // Step 1: Extract text using Vision OCR
        let extractedText = try await extractText(from: image)

        // Step 2: Parse text into recipe structure using AI
        let recipe = try await parseRecipe(from: extractedText, using: geminiService)

        return recipe
    }
}
