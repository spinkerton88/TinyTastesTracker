//
//  CustomFood.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CustomFood: Codable {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var category: FoodCategory
    var allergens: [String]
    var allergyRisk: AllergyRisk? // Optional to handle migration from old data
    var nutritionHighlights: String
    var howToServe: String
    var chokeHazard: Bool
    var color: FoodColor
    var containedColors: [FoodColor]
    var containedCategories: [FoodCategory] // New property for multi-category tracking
    var nutrients: [Nutrient]
    var createdAt: Date
    var imageFileName: String?
    
    init(id: String, name: String, emoji: String, category: FoodCategory,
         allergens: [String] = [], allergyRisk: AllergyRisk? = .low,
         nutritionHighlights: String = "",
         howToServe: String = "", chokeHazard: Bool = false,
         color: FoodColor = .brown, containedColors: [FoodColor] = [],
         containedCategories: [FoodCategory] = [],
         nutrients: [Nutrient] = [], createdAt: Date = Date(),
         imageFileName: String? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.category = category
        self.allergens = allergens
        self.allergyRisk = allergyRisk
        self.nutritionHighlights = nutritionHighlights
        self.howToServe = howToServe
        self.chokeHazard = chokeHazard
        self.color = color
        self.containedColors = containedColors
        self.containedCategories = containedCategories
        self.nutrients = nutrients
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }

    // Convert to FoodItem for UI compatibility
    var toFoodItem: FoodItem {
        // Note: FoodItem struct is rigid, but we can access the CustomFood directly in logic where needed
        FoodItem(
            id: id,
            name: name,
            emoji: emoji,
            category: category,
            allergens: allergens,
            allergyRisk: allergyRisk ?? .low, // Provide default for old records
            nutritionHighlights: nutritionHighlights,
            howToServe: howToServe,
            chokeHazard: chokeHazard,
            color: color,
            nutrients: nutrients,
            imageFileName: imageFileName
        )
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, category, allergens, allergyRisk, nutritionHighlights, howToServe, chokeHazard, color, containedColors, containedCategories, nutrients, createdAt, imageFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.category = try container.decode(FoodCategory.self, forKey: .category)
        self.allergens = try container.decode([String].self, forKey: .allergens)
        self.allergyRisk = try container.decodeIfPresent(AllergyRisk.self, forKey: .allergyRisk) ?? .low
        self.nutritionHighlights = try container.decode(String.self, forKey: .nutritionHighlights)
        self.howToServe = try container.decode(String.self, forKey: .howToServe)
        self.chokeHazard = try container.decode(Bool.self, forKey: .chokeHazard)
        self.color = try container.decode(FoodColor.self, forKey: .color)
        self.containedColors = try container.decodeIfPresent([FoodColor].self, forKey: .containedColors) ?? []
        self.containedCategories = try container.decodeIfPresent([FoodCategory].self, forKey: .containedCategories) ?? []
        self.nutrients = try container.decode([Nutrient].self, forKey: .nutrients)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(category, forKey: .category)
        try container.encode(allergens, forKey: .allergens)
        try container.encode(allergyRisk, forKey: .allergyRisk)
        try container.encode(nutritionHighlights, forKey: .nutritionHighlights)
        try container.encode(howToServe, forKey: .howToServe)
        try container.encode(chokeHazard, forKey: .chokeHazard)
        try container.encode(color, forKey: .color)
        try container.encode(containedColors, forKey: .containedColors)
        try container.encode(containedCategories, forKey: .containedCategories)
        try container.encode(nutrients, forKey: .nutrients)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
    }
}
