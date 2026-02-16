//
//  MealPlan.swift
//  TinyTastesTracker
//
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum MealItemType: String, Codable {
    case recipe
    case food
}

struct MealPlanEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var childId: String // Meal plans are specific to a child (or potentially shared, but usually child)
    
    var date: Date = Date()
    var mealType: MealType = MealType.lunch
    var itemType: MealItemType = MealItemType.recipe

    // Recipe fields (used when itemType == .recipe)
    var recipeId: String? // Changed from UUID
    var recipeName: String?

    // Food fields (used when itemType == .food)
    var foodId: String?
    var foodName: String?

    var sortOrder: Int = 0 // For ordering multiple items in same slot

    // Convenience init for recipes
    init(id: String? = nil, ownerId: String, childId: String, date: Date, mealType: MealType, recipeId: String, recipeName: String, sortOrder: Int = 0) {
        self.init(id: id, ownerId: ownerId, childId: childId, date: date, mealType: mealType, itemType: .recipe, recipeId: recipeId, recipeName: recipeName, foodId: nil, foodName: nil, sortOrder: sortOrder)
    }

    // Init for foods
    init(id: String? = nil, ownerId: String, childId: String, date: Date, mealType: MealType, foodId: String, foodName: String, sortOrder: Int = 0) {
        self.init(id: id, ownerId: ownerId, childId: childId, date: date, mealType: mealType, itemType: .food, recipeId: nil, recipeName: nil, foodId: foodId, foodName: foodName, sortOrder: sortOrder)
    }

    // Full init
    init(id: String? = nil, ownerId: String, childId: String, date: Date, mealType: MealType, itemType: MealItemType, recipeId: String?, recipeName: String?, foodId: String?, foodName: String?, sortOrder: Int = 0) {
        self.id = id
        self.ownerId = ownerId
        self.childId = childId
        self.date = date
        self.mealType = mealType
        self.itemType = itemType
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.foodId = foodId
        self.foodName = foodName
        self.sortOrder = sortOrder
    }

    // Computed property for display name
    var displayName: String {
        switch itemType {
        case .recipe:
            return recipeName ?? "Unknown Recipe"
        case .food:
            return foodName ?? "Unknown Food"
        }
    }
}

enum ItemSource: String, Codable {
    case recipe
    case manual
}

struct ShoppingListItem: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var sharedWith: [String]? // User IDs who have access via profile sharing

    var name: String = ""
    var quantity: String?
    var unit: String?
    var category: GroceryCategory = GroceryCategory.other
    var isCompleted: Bool = false
    var source: ItemSource = ItemSource.manual
    var createdAt: Date = Date()
    
    init(id: String? = nil, ownerId: String, name: String, quantity: String? = nil, unit: String? = nil, category: GroceryCategory = .other, isCompleted: Bool = false, source: ItemSource = .manual) {
        self.id = id
        self.ownerId = ownerId
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
