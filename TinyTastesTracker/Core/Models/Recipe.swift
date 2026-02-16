//
//  Recipe.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Recipe: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var sharedWith: [String]? // User IDs who have access via profile sharing

    var title: String = ""
    var ingredients: String = ""
    var instructions: String = ""
    var tags: [String] = []
    var mealTypes: [MealType] = []
    var createdAt: Date = Date()
    
    // External storage logic is handled by services, but we keep the property for now.
    // In a real Firestore app, we would store the URL string here, not the Data.
    // However, keeping Data? to match previous model for now, but note robust implementation
    // should use StorageReference or URL string.
    var imageData: Data?
    var thumbnailData: Data?
    
    init(id: String? = nil,
         ownerId: String,
         title: String,
         ingredients: String,
         instructions: String,
         tags: [String] = [],
         mealTypes: [MealType] = [],
         imageData: Data? = nil,
         thumbnailData: Data? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.tags = tags
        self.mealTypes = mealTypes
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
    }
    
    // MARK: - Helpers
    
    var parsedIngredients: [String] {
        // Try newline separation first
        var items = ingredients.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasPrefix("- ") ? String($0.dropFirst(2)) : $0 }
            .filter { !$0.isEmpty }
        
        // If only one item after newline split, try smart comma separation
        if items.count <= 1 {
            items = smartSplit(ingredients, separator: ",")
        }
        
        return items.isEmpty ? [ingredients] : items
    }
    
    var parsedInstructions: [String] {
        // Try newline separation first
        var items = instructions.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line -> String in
                // Remove leading number patterns like "1.", "1)", "1:"
                var cleaned = line
                if let range = cleaned.range(of: "^\\d+[\\.\\)\\:]\\s*", options: .regularExpression) {
                    cleaned = String(cleaned[range.upperBound...])
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
        
        // If only one item after newline split, try splitting by numbered steps (e.g. "1. Step one 2. Step two")
        if items.count <= 1 {
            // Pattern: look for "N. "
            // We iterate manually to slice the string safely
            do {
                let pattern = "\\d+\\.\\s+"
                let regex = try NSRegularExpression(pattern: pattern)
                let nsString = instructions as NSString
                let matches = regex.matches(in: instructions, range: NSRange(location: 0, length: nsString.length))
                
                if matches.count > 0 {
                    var result: [String] = []
                    for i in 0..<matches.count {
                        let start = matches[i].range.location
                        let end = (i < matches.count - 1) ? matches[i+1].range.location : nsString.length
                        let range = NSRange(location: start, length: end - start)
                        
                        if range.length > 0 {
                            let substring = nsString.substring(with: range)
                            // Clean the leading "N. "
                            let cleaned = substring.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !cleaned.isEmpty {
                                result.append(cleaned)
                            }
                        }
                    }
                    items = result
                }
            } catch {
                print("Regex parsing error: \(error)")
            }
        }
        
        return items.isEmpty ? [instructions] : items
    }
    
    private func smartSplit(_ text: String, separator: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var depth = 0
        
        for char in text {
            if char == "(" { depth += 1 }
            else if char == ")" { depth -= 1 }
            
            if char == separator && depth == 0 {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result.filter { !$0.isEmpty }
    }
}
