//
//  MealPlan.swift
//  TinyTastesTracker
//

import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealType: MealType
    var recipeId: UUID
    var recipeName: String
    
    init(id: UUID = UUID(), date: Date, mealType: MealType, recipeId: UUID, recipeName: String) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.recipeId = recipeId
        self.recipeName = recipeName
    }
}

enum ItemSource: String, Codable {
    case recipe
    case manual
}

@Model
final class ShoppingListItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String?
    var unit: String?
    var category: GroceryCategory
    var isCompleted: Bool
    var source: ItemSource
    var createdAt: Date

    init(id: UUID = UUID(), name: String, quantity: String? = nil, unit: String? = nil, category: GroceryCategory = .other, isCompleted: Bool = false, source: ItemSource = .manual) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isCompleted = isCompleted
        self.source = source
        self.createdAt = Date()
    }
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy & Eggs"
    case meatSeafood = "Meat & Seafood"
    case pantry = "Pantry & Dry Goods"
    case frozen = "Frozen"
    case bakery = "Bakery"
    case beverages = "Beverages"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .produce: return "🥬"
        case .dairy: return "🥛"
        case .meatSeafood: return "🍖"
        case .pantry: return "🥫"
        case .frozen: return "🧊"
        case .bakery: return "🍞"
        case .beverages: return "🥤"
        case .other: return "🛒"
        }
    }
}

