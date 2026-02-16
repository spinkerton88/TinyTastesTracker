//
//  CustomFood.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

struct CustomFood: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var sharedWith: [String]? // User IDs who have access via profile sharing

    var name: String = ""
    var emoji: String = "🍎"
    var category: FoodCategory = FoodCategory.fruits
    var allergens: [String] = []
    var allergyRisk: AllergyRisk? // Optional to handle migration from old data
    var nutritionHighlights: String = ""
    var howToServe: String = ""
    var chokeHazard: Bool = false
    var color: FoodColor = FoodColor.red
    var containedColors: [FoodColor] = []
    var containedCategories: [FoodCategory] = [] // New property for multi-category tracking
    var nutrients: [Nutrient] = []
    var createdAt: Date = Date()
    var imageFileName: String? // Deprecated: kept for backward compatibility
    var imageStoragePath: String? // Firebase Storage path for cloud sync

    init(id: String? = nil, 
         ownerId: String,
         name: String, 
         emoji: String, 
         category: FoodCategory,
         allergens: [String] = [], 
         allergyRisk: AllergyRisk? = .low,
         nutritionHighlights: String = "",
         howToServe: String = "", 
         chokeHazard: Bool = false,
         color: FoodColor = .brown, 
         containedColors: [FoodColor] = [],
         containedCategories: [FoodCategory] = [],
         nutrients: [Nutrient] = [],
         createdAt: Date = Date(),
         imageFileName: String? = nil,
         imageStoragePath: String? = nil) {
        self.id = id
        self.ownerId = ownerId
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
        self.imageStoragePath = imageStoragePath
    }

    // Convert to FoodItem for UI compatibility
    var toFoodItem: FoodItem {
        // Note: FoodItem struct is rigid, but we can access the CustomFood directly in logic where needed
        FoodItem(
            id: id ?? UUID().uuidString, // Fallback ID if not yet saved
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
            imageFileName: imageFileName,
            imageStoragePath: imageStoragePath
        )
    }
    
    static let empty = CustomFood(ownerId: "empty", name: "Unknown", emoji: "❓", category: .vegetables)
}
