//
//  RecipeManager.swift
//  TinyTastesTracker
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class RecipeManager {
    var recipes: [Recipe] = []
    var mealPlanEntries: [MealPlanEntry] = []
    var shoppingListItems: [ShoppingListItem] = []
    var customFoods: [CustomFood] = []

    // Dependency injection for AI service
    weak var aiServiceManager: AIServiceManager?
    
    // Pagination support
    var recipesOffset = 0
    let recipesPageSize = 20
    var hasMoreRecipes = true
    var totalRecipeCount = 0

    // MARK: - Computed Properties

    var allKnownFoods: [FoodItem] {
        // Include all custom foods, including recipes (essential for logs and stats)
        return Constants.allFoods + customFoods.map { $0.toFoodItem }
    }

    // MARK: - Recipe Management

    func saveRecipe(_ recipe: Recipe, context: ModelContext) {
        recipes.append(recipe)
        context.insert(recipe)
    }

    func deleteRecipe(_ recipe: Recipe, context: ModelContext) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes.remove(at: index)
        }
        context.delete(recipe)
    }

    // MARK: - Custom Foods

    func saveCustomFood(_ food: CustomFood, context: ModelContext) {
        if let existingIndex = customFoods.firstIndex(where: { $0.id == food.id }) {
            customFoods[existingIndex] = food
        } else {
            customFoods.append(food)
            context.insert(food)
        }
    }

    func createCustomFoodFromRecipe(_ recipe: Recipe, context: ModelContext) -> CustomFood {
        // Check if already exists
        let id = "RECIPE_\(recipe.id.uuidString)"
        if let existing = customFoods.first(where: { $0.id == id }) {
            return existing
        }

        // Synchronously aggregate details from known ingredients
        var aggregatedColors: Set<FoodColor> = []
        var aggregatedCategories: Set<FoodCategory> = []
        var aggregatedNutrients: Set<Nutrient> = []
        
        let knownFoods = allKnownFoods // Cache access
        
        for ingredientLine in recipe.parsedIngredients {
            let parsed = parseIngredient(ingredientLine)
            let name = parsed.name
            
            // Try explicit match first, then fuzzy
            if let match = knownFoods.first(where: { 
                $0.name.localizedCaseInsensitiveContains(name) || 
                name.localizedCaseInsensitiveContains($0.name) 
            }) {
                aggregatedColors.insert(match.color)
                aggregatedCategories.insert(match.category)
                match.nutrients.forEach { aggregatedNutrients.insert($0) }
            }
        }
        
        // Determine defaults if nothing found
        let primaryCategory = aggregatedCategories.first ?? .proteins
        let primaryColor = aggregatedColors.first ?? .brown
        let nutritionText = aggregatedNutrients.isEmpty ? "Home cooked meal" : 
                            Array(aggregatedNutrients).map { $0.rawValue.capitalized }.joined(separator: ", ")

        // Create with aggregated data
        let newFood = CustomFood(
            id: id,
            name: recipe.title,
            emoji: "🍲",
            category: primaryCategory,
            allergens: [],
            nutritionHighlights: nutritionText,
            howToServe: "Serve appropriately for age",
            chokeHazard: false,
            color: primaryColor,
            containedColors: Array(aggregatedColors),
            containedCategories: Array(aggregatedCategories),
            nutrients: Array(aggregatedNutrients)
        )

        saveCustomFood(newFood, context: context)

        // Trigger background analysis to refine details
        let foodID = newFood.id
        let recipeTitle = recipe.title
        let recipeIngredients = recipe.ingredients
        
        Task { [weak self] in
            do {
                guard let self else { return }
                guard let aiService = self.aiServiceManager else { return }
                let details = try await aiService.analyzeRecipe(title: recipeTitle, ingredients: recipeIngredients)

                // Update on MainActor
                await MainActor.run {
                    // Re-fetch the food object safely on MainActor
                    if let foodToUpdate = self.customFoods.first(where: { $0.id == foodID }) {
                        foodToUpdate.emoji = details.emoji
                        foodToUpdate.category = FoodCategory(rawValue: details.category.lowercased()) ?? .proteins
                        foodToUpdate.allergens = details.allergens
                        foodToUpdate.nutritionHighlights = details.nutritionHighlights
                        foodToUpdate.howToServe = details.howToServe
                        foodToUpdate.chokeHazard = details.chokeHazard
                        foodToUpdate.color = FoodColor(rawValue: details.color.capitalized) ?? .brown
                        if let contained = details.containedColors {
                            foodToUpdate.containedColors = contained.compactMap { FoodColor(rawValue: $0.capitalized) }
                        }
                        if let categories = details.containedCategories {
                            foodToUpdate.containedCategories = categories.compactMap { FoodCategory(rawValue: $0.lowercased()) }
                        }
                        foodToUpdate.nutrients = details.nutrients.compactMap { Nutrient(rawValue: $0) }
                    }
                }
            } catch {
                print("Failed to analyze recipe: \(error)")
                await MainActor.run {
                    ErrorPresenter.shared.present(error)
                }
            }
        }

        return newFood
    }

    // MARK: - Meal Planning

    func addMealPlanEntry(_ entry: MealPlanEntry, context: ModelContext) {
        mealPlanEntries.append(entry)
        context.insert(entry)
    }

    func removeMealPlanEntry(_ entry: MealPlanEntry, context: ModelContext) {
        if let index = mealPlanEntries.firstIndex(where: { $0.id == entry.id }) {
            mealPlanEntries.remove(at: index)
        }
        context.delete(entry)
    }

    func getMealPlanEntries(for date: Date) -> [MealType: MealPlanEntry] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return [:]
        }

        let entries = mealPlanEntries.filter { entry in
            entry.date >= dayStart && entry.date < dayEnd
        }

        var result: [MealType: MealPlanEntry] = [:]
        for entry in entries {
            result[entry.mealType] = entry
        }
        return result
    }

    // MARK: - Shopping List

    func addShoppingListItem(_ item: ShoppingListItem, context: ModelContext) {
        shoppingListItems.append(item)
        context.insert(item)
    }

    func toggleShoppingItemComplete(_ item: ShoppingListItem) {
        item.isCompleted.toggle()
    }

    func removeShoppingListItem(_ item: ShoppingListItem, context: ModelContext) {
        if let index = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
            shoppingListItems.remove(at: index)
        }
        context.delete(item)
    }

    func generateShoppingListFromMealPlan(context: ModelContext) {
        // Clear existing recipe-sourced items
        let recipeItems = shoppingListItems.filter { $0.source == .recipe }
        for item in recipeItems {
            removeShoppingListItem(item, context: context)
        }

        // Get all unique recipes from meal plan
        let recipeIds = Set(mealPlanEntries.map { $0.recipeId })
        let plannedRecipes = recipes.filter { recipeIds.contains($0.id) }

        // Extract and parse ingredients
        var parsedItems: [ShoppingListItem] = []
        for recipe in plannedRecipes {
            for ingredient in recipe.parsedIngredients {
                let parsed = parseIngredient(ingredient)
                let category = categorizeIngredient(parsed.name)
                let item = ShoppingListItem(
                    name: parsed.name,
                    quantity: parsed.quantity,
                    unit: parsed.unit,
                    category: category,
                    source: .recipe
                )
                parsedItems.append(item)
            }
        }

        // Consolidate duplicate items
        let consolidatedItems = consolidateShoppingItems(parsedItems)
        
        // Add to shopping list
        for item in consolidatedItems {
            addShoppingListItem(item, context: context)
        }
    }
    
    // MARK: - Ingredient Parsing Helpers
    
    func parseIngredient(_ ingredient: String) -> (quantity: String?, unit: String?, name: String) {
        let trimmed = ingredient.trimmingCharacters(in: .whitespaces)
        
        // Common units to detect
        let units = ["cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
                     "oz", "ounce", "ounces", "lb", "lbs", "pound", "pounds", "g", "gram", "grams",
                     "kg", "kilogram", "kilograms", "ml", "milliliter", "milliliters", "l", "liter", "liters",
                     "clove", "cloves", "bunch", "bunches", "can", "cans", "package", "packages",
                     "slice", "slices", "piece", "pieces", "pinch", "dash"]
        
        // Pattern: [quantity] [unit] [name]
        let components = trimmed.components(separatedBy: " ")
        guard components.count >= 2 else {
            return (nil, nil, trimmed)
        }
        
        // Try to extract quantity (first component)
        var quantity: String?
        var unit: String?
        var nameStartIndex = 0
        
        // Check if first component is a number or fraction
        let firstComponent = components[0]
        if firstComponent.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789/.-")) != nil {
            quantity = firstComponent
            nameStartIndex = 1
            
            // Check if second component is a unit
            if components.count > 1 {
                let secondComponent = components[1].lowercased()
                if units.contains(where: { secondComponent.hasPrefix($0) }) {
                    unit = components[1]
                    nameStartIndex = 2
                }
            }
        }
        
        // Extract name (remaining components)
        let name = components[nameStartIndex...].joined(separator: " ")
        
        return (quantity, unit, name.isEmpty ? trimmed : name)
    }
    
    func categorizeIngredient(_ name: String) -> GroceryCategory {
        let lowercased = name.lowercased()
        
        // Produce keywords
        let produceKeywords = ["lettuce", "tomato", "onion", "garlic", "carrot", "celery", "pepper", "spinach",
                               "kale", "broccoli", "cauliflower", "cucumber", "zucchini", "squash", "potato",
                               "apple", "banana", "orange", "lemon", "lime", "berry", "berries", "avocado",
                               "mushroom", "herb", "parsley", "cilantro", "basil", "thyme", "rosemary"]
        
        // Dairy keywords
        let dairyKeywords = ["milk", "cream", "cheese", "butter", "yogurt", "egg", "eggs", "sour cream",
                            "cottage cheese", "cheddar", "mozzarella", "parmesan"]
        
        // Meat & Seafood keywords
        let meatKeywords = ["chicken", "beef", "pork", "turkey", "lamb", "fish", "salmon", "tuna",
                           "shrimp", "meat", "bacon", "sausage", "ground beef", "steak"]
        
        // Pantry keywords
        let pantryKeywords = ["flour", "sugar", "salt", "pepper", "oil", "olive oil", "vinegar", "rice",
                             "pasta", "noodle", "bean", "beans", "lentil", "quinoa", "oat", "cereal",
                             "sauce", "stock", "broth", "can", "canned", "jar", "spice", "seasoning"]
        
        // Frozen keywords
        let frozenKeywords = ["frozen", "ice cream", "popsicle"]
        
        // Bakery keywords
        let bakeryKeywords = ["bread", "bun", "roll", "bagel", "tortilla", "pita", "croissant", "muffin"]
        
        // Beverages keywords
        let beverageKeywords = ["juice", "soda", "water", "tea", "coffee", "drink", "beverage"]
        
        // Check categories in order
        if produceKeywords.contains(where: { lowercased.contains($0) }) {
            return .produce
        } else if dairyKeywords.contains(where: { lowercased.contains($0) }) {
            return .dairy
        } else if meatKeywords.contains(where: { lowercased.contains($0) }) {
            return .meatSeafood
        } else if frozenKeywords.contains(where: { lowercased.contains($0) }) {
            return .frozen
        } else if bakeryKeywords.contains(where: { lowercased.contains($0) }) {
            return .bakery
        } else if beverageKeywords.contains(where: { lowercased.contains($0) }) {
            return .beverages
        } else if pantryKeywords.contains(where: { lowercased.contains($0) }) {
            return .pantry
        }
        
        return .other
    }
    
    func consolidateShoppingItems(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
        var consolidated: [String: ShoppingListItem] = [:]
        
        for item in items {
            let key = item.name.lowercased()
            
            if let existing = consolidated[key] {
                // If both have quantities, try to combine
                if let existingQty = existing.quantity,
                   let newQty = item.quantity,
                   existing.unit == item.unit,
                   let existingNum = Double(existingQty),
                   let newNum = Double(newQty) {
                    // Can combine numeric quantities with same unit
                    let combined = existingNum + newNum
                    existing.quantity = String(format: "%.1f", combined).replacingOccurrences(of: ".0", with: "")
                } else if existing.quantity == nil && item.quantity != nil {
                    // Update with quantity info if existing doesn't have it
                    existing.quantity = item.quantity
                    existing.unit = item.unit
                }
            } else {
                consolidated[key] = item
            }
        }
        
        return Array(consolidated.values).sorted { $0.name < $1.name }
    }


    // MARK: - Data Loading

    func loadData(context: ModelContext) {
        do {
            // Performance optimization: Load only first page of recipes initially
            recipesOffset = 0
            
            // Get total count for pagination
            let countDescriptor = FetchDescriptor<Recipe>()
            totalRecipeCount = try context.fetchCount(countDescriptor)
            
            // Load first page
            var recipeDescriptor = FetchDescriptor<Recipe>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            recipeDescriptor.fetchLimit = recipesPageSize
            recipeDescriptor.fetchOffset = 0
            recipes = try context.fetch(recipeDescriptor)
            
            hasMoreRecipes = recipes.count < totalRecipeCount

            // Load all custom foods (typically small dataset)
            let customFoodDescriptor = FetchDescriptor<CustomFood>(sortBy: [SortDescriptor(\.createdAt)])
            customFoods = try context.fetch(customFoodDescriptor)

            // Load only future meal plan entries (no need for historical meal plans)
            let today = Calendar.current.startOfDay(for: Date())
            let mealPlanDescriptor = FetchDescriptor<MealPlanEntry>(
                predicate: #Predicate { $0.date >= today },
                sortBy: [SortDescriptor(\.date)]
            )
            mealPlanEntries = try context.fetch(mealPlanDescriptor)

            // Load active shopping list items
            let shoppingDescriptor = FetchDescriptor<ShoppingListItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            shoppingListItems = try context.fetch(shoppingDescriptor)
        } catch {
            print("Error loading recipe data: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
    
    /// Load more recipes (pagination)
    /// - Parameter context: SwiftData ModelContext
    func loadMoreRecipes(context: ModelContext) {
        guard hasMoreRecipes else { return }
        
        do {
            recipesOffset += recipesPageSize
            
            var recipeDescriptor = FetchDescriptor<Recipe>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            recipeDescriptor.fetchLimit = recipesPageSize
            recipeDescriptor.fetchOffset = recipesOffset
            
            let moreRecipes = try context.fetch(recipeDescriptor)
            recipes.append(contentsOf: moreRecipes)
            
            hasMoreRecipes = recipes.count < totalRecipeCount
        } catch {
            print("Error loading more recipes: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
}
