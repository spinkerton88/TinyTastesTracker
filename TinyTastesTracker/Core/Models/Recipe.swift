//
//  Recipe.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import SwiftData

@Model
final class Recipe: Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var ingredients: String
    var instructions: String
    var tags: [String]
    var mealTypes: [MealType]
    var createdAt: Date
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    init(id: UUID = UUID(),
         title: String,
         ingredients: String,
         instructions: String,
         tags: [String] = [],
         mealTypes: [MealType] = [],
         imageData: Data? = nil,
         thumbnailData: Data? = nil,
         createdAt: Date = Date()) {
        self.id = id
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
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, title, ingredients, instructions, tags, mealTypes, imageData, thumbnailData, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.ingredients = try container.decode(String.self, forKey: .ingredients)
        self.instructions = try container.decode(String.self, forKey: .instructions)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.mealTypes = try container.decode([MealType].self, forKey: .mealTypes)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        self.thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(tags, forKey: .tags)
        try container.encode(mealTypes, forKey: .mealTypes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encodeIfPresent(thumbnailData, forKey: .thumbnailData)
    }
}
