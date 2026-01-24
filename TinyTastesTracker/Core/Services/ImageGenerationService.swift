//
//  ImageGenerationService.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 01/16/26.
//

import Foundation
import UIKit

enum ImageGenerationError: Error {
    case invalidURL
    case apiError(String)
    case invalidResponse
    case decodingError
}

class ImageGenerationService {
    static let shared = ImageGenerationService()
    

    // MARK: - Image Generation Logic

    /// Generates a food image using Google Imagen 4.
    /// Priority:
    /// 1. `imagen-4.0-generate-001` (Standard - High Quality)
    /// 2. `imagen-4.0-fast-generate-001` (Fast - Backup)
    /// 3. Placeholder (Final Fallback)
    func generateFoodImage(for foodName: String) async throws -> UIImage {
        // Obfuscated Key Retrieval
        guard let apiKey = SecureAPIKeyManager.shared.getAPIKey() else {
            print("❌ No API Key found.")
            return createStyledPlaceholder(for: foodName)
        }
        
        // 1. Try Standard Model
        do {
            return try await generateViaGoogle(model: "imagen-4.0-generate-001", foodName: foodName, apiKey: apiKey)
        } catch {
            print("⚠️ Standard model failed: \(error). Retrying with Fast model...")
        }
        
        // 2. Try Fast Model (Backup)
        do {
            // Use a slightly simplified prompt for the 'fast' model to avoid hallucinations
            return try await generateViaGoogle(model: "imagen-4.0-fast-generate-001", foodName: foodName, apiKey: apiKey, simplified: true)
        } catch {
            print("❌ Fast model also failed: \(error). Returning placeholder.")
        }
        
        // 3. Final Fallback
        return createStyledPlaceholder(for: foodName)
    }
    
    private func generateViaGoogle(model: String, foodName: String, apiKey: String, simplified: Bool = false) async throws -> UIImage {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):predict?key=\(apiKey)"
        
        guard let url = URL(string: endpoint) else {
            throw ImageGenerationError.invalidURL
        }
        
        // Dynamic Prompting
        let prompt: String
        if simplified {
            // Simplified prompt for Fast model / Backup
            prompt = "Object photo of fresh \(foodName), isolated on a solid middle gray background, sharp focus, natural lighting"
        } else {
            // High-quality prompt for Standard model
            prompt = """
            Professional gourmet studio photography of a whole raw \(foodName), isolated on a solid middle gray background, \
            cinematic lighting, rim light to separate from background, \
            4k resolution, ultra-detailed texture, glistening fresh surface, sharp focus, \
            shot on 100mm macro lens, f/8, highly appetizing
            """
        }
        
        let payload: [String: Any] = [
            "instances": [
                ["prompt": prompt]
            ],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": "1:1"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageGenerationError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw ImageGenerationError.apiError("Status: \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictions = json["predictions"] as? [[String: Any]],
              let firstPrediction = predictions.first,
              let base64String = firstPrediction["bytesBase64Encoded"] as? String,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            throw ImageGenerationError.decodingError
        }
        
        print("✅ Generated image for '\(foodName)' using \(model)")
        return image
    }

    
    // Creates a professional placeholder for offline/error cases
    private func createStyledPlaceholder(for foodName: String) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Gradient background based on food name hash
            let hue = CGFloat(abs(foodName.hashValue) % 360) / 360.0
            let topColor = UIColor(hue: hue, saturation: 0.3, brightness: 0.95, alpha: 1.0)
            let bottomColor = UIColor(hue: hue, saturation: 0.15, brightness: 0.98, alpha: 1.0)
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )
            
            // Draw the first letter
            let letter = String(foodName.prefix(1)).uppercased()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 280, weight: .bold),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor(white: 0.3, alpha: 0.15)
            ]
            
            let string = letter as NSString
            let stringSize = string.size(withAttributes: attrs)
            let stringRect = CGRect(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            
            string.draw(in: stringRect, withAttributes: attrs)
            
            // Add food name at bottom
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor(white: 0.4, alpha: 0.6)
            ]
            
            let nameString = foodName as NSString
            let nameSize = nameString.size(withAttributes: nameAttrs)
            let nameRect = CGRect(
                x: (size.width - nameSize.width) / 2,
                y: size.height - nameSize.height - 40,
                width: nameSize.width,
                height: nameSize.height
            )
            
            nameString.draw(in: nameRect, withAttributes: nameAttrs)
            
            nameString.draw(in: nameRect, withAttributes: nameAttrs)
        }
    }
    
    // Check if a local image exists for a food ID
    func hasLocalImage(for foodId: String) -> Bool {
        let fileName = "food_\(foodId.lowercased().replacingOccurrences(of: " ", with: "_")).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // Save image to Documents directory with standardized naming
    func saveImageForFood(image: UIImage, foodId: String) -> String? {
        let fileName = "food_\(foodId.lowercased().replacingOccurrences(of: " ", with: "_")).png"
        return saveImageToDocuments(image, fileName: fileName)
    }
    
    private func saveImageToDocuments(_ image: UIImage, fileName: String) -> String? {
        guard let data = image.pngData() else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}
