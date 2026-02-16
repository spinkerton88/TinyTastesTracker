//
//  RecipeManager.swift
//  TinyTastesTracker
//
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAnalytics
import Combine

@Observable
class RecipeManager {
    // Data Arrays (synced via Firestore)
    var recipes: [Recipe] = []
    var mealPlanEntries: [MealPlanEntry] = []
    var shoppingListItems: [ShoppingListItem] = []
    var customFoods: [CustomFood] = []

    // Internal arrays for merging owned + shared data
    private var ownedRecipes: [Recipe] = []
    private var sharedRecipes: [Recipe] = []
    private var ownedCustomFoods: [CustomFood] = []
    private var sharedCustomFoods: [CustomFood] = []
    private var ownedShoppingItems: [ShoppingListItem] = []
    private var sharedShoppingItems: [ShoppingListItem] = []

    // Firestore Services
    private let recipeService = FirestoreService<Recipe>(collectionName: "recipes")
    private let customFoodService = FirestoreService<CustomFood>(collectionName: "custom_foods")
    private let mealPlanService = FirestoreService<MealPlanEntry>(collectionName: "meal_plan_entries")
    private let shoppingListService = FirestoreService<ShoppingListItem>(collectionName: "shopping_list_items")

    // Direct Firestore reference for shared queries
    private let db = Firestore.firestore()

    // Listeners
    private var listeners: [ListenerRegistration] = []
    
    // Dependency injection for AI service
    weak var aiServiceManager: AIServiceManager?
    
    // Pagination support (simplified for Firestore initially, fetching all or limited set)
    var recipesOffset = 0
    let recipesPageSize = 20
    var hasMoreRecipes = false // Pagination disabled for now in favor of live listener
    var totalRecipeCount = 0

    deinit {
        listeners.forEach { $0.remove() }
    }

    // MARK: - Computed Properties

    var allKnownFoods: [FoodItem] {
        // Include all custom foods, including recipes (essential for logs and stats)
        return Constants.allFoods + customFoods.map { $0.toFoodItem }
    }

    // MARK: - Recipe Management

    func saveRecipe(_ recipe: Recipe, ownerId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(recipe) {
                let operation = QueuedOperation(
                    type: .recipe,
                    payload: encoded,
                    priority: .normal
                )
                OfflineQueue.shared.enqueue(operation)
            }
            throw FirebaseError.networkUnavailable
        }

        let isNew = recipe.id == nil

        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                if recipe.id != nil {
                    try await self.recipeService.update(recipe)
                } else {
                    try await self.recipeService.add(recipe)
                }
            }
        }

        // Track analytics event
        if isNew {
            Analytics.logEvent("recipe_created", parameters: [
                "difficulty": recipe.difficulty?.rawValue ?? "unknown",
                "ingredient_count": recipe.ingredients.count,
                "source": recipe.sourceType == .aiGenerated ? "ai" : "manual"
            ])
        }
    }

    func deleteRecipe(_ recipe: Recipe) {
        guard let id = recipe.id else { return }
        Task { try? await recipeService.delete(id: id) }
    }

    // MARK: - Custom Foods

    func saveCustomFood(_ food: CustomFood, ownerId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(food) {
                let operation = QueuedOperation(
                    type: .customFood,
                    payload: encoded,
                    priority: .normal
                )
                OfflineQueue.shared.enqueue(operation)
            }
            throw FirebaseError.networkUnavailable
        }
        
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                if food.id != nil {
                    try await self.customFoodService.update(food)
                } else {
                    try await self.customFoodService.add(food)
                }
            }
        }
    }

    /// Save a custom food with an image - uploads image to Firebase Storage
    func saveCustomFoodWithImage(_ food: CustomFood, image: UIImage, ownerId: String) async throws -> CustomFood {
        // Generate food ID if needed
        let foodId = food.id ?? UUID().uuidString

        // Upload image to Firebase Storage
        let storagePath = try await FoodImageStorageService.shared.uploadFoodImage(
            image,
            foodId: foodId,
            ownerId: ownerId
        )

        // Update food with storage path
        var updatedFood = food
        updatedFood.imageStoragePath = storagePath

        // If no ID yet, set it
        if updatedFood.id == nil {
            updatedFood.id = foodId
        }

        // Save to Firestore
        do {
            if updatedFood.id != nil {
                try await customFoodService.update(updatedFood)
            } else {
                try await customFoodService.add(updatedFood)
            }
        } catch {
            print("Error saving custom food: \(error)")
            throw error
        }

        return updatedFood
    }

    func deleteCustomFood(_ food: CustomFood) {
        guard let id = food.id else { return }

        // Delete image from storage if exists
        if let storagePath = food.imageStoragePath {
            Task {
                try? await FoodImageStorageService.shared.deleteFoodImage(storagePath: storagePath)
            }
        }

        Task { try? await customFoodService.delete(id: id) }
    }

    func createCustomFoodFromRecipe(_ recipe: Recipe, ownerId: String) -> CustomFood {
        // Check if already exists
        let recipeIdString = recipe.id ?? UUID().uuidString
        let id = "RECIPE_\(recipeIdString)"

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
            let name = parsed.name.lowercased()

            // Try multiple matching strategies
            var matched = false

            // Strategy 1: Exact match (case-insensitive)
            if let match = knownFoods.first(where: { $0.name.lowercased() == name }) {
                aggregatedColors.insert(match.color)
                aggregatedCategories.insert(match.category)
                match.nutrients.forEach { aggregatedNutrients.insert($0) }
                matched = true
            }

            // Strategy 2: Contains match (ingredient name contains food name or vice versa)
            if !matched, let match = knownFoods.first(where: {
                $0.name.lowercased().contains(name) || name.contains($0.name.lowercased())
            }) {
                aggregatedColors.insert(match.color)
                aggregatedCategories.insert(match.category)
                match.nutrients.forEach { aggregatedNutrients.insert($0) }
                matched = true
            }

            // Strategy 3: Word-based matching (split into words and match any word)
            if !matched {
                let nameWords = name.components(separatedBy: " ").filter { $0.count > 3 } // Skip small words like "of", "the"
                for word in nameWords {
                    if let match = knownFoods.first(where: {
                        $0.name.lowercased().contains(word) ||
                        $0.id.lowercased().contains(word.uppercased())
                    }) {
                        aggregatedColors.insert(match.color)
                        aggregatedCategories.insert(match.category)
                        match.nutrients.forEach { aggregatedNutrients.insert($0) }
                        break // Only match once per ingredient
                    }
                }
            }
        }

        // Determine defaults if nothing found
        let primaryCategory = aggregatedCategories.first ?? .proteins
        let primaryColor = aggregatedColors.first ?? .brown
        let nutritionText = aggregatedNutrients.isEmpty ? "Home cooked meal" :
                            Array(aggregatedNutrients).map { $0.rawValue.capitalized }.joined(separator: ", ")

        // Create with aggregated data
        var newFood = CustomFood(
            id: id, // Explicit ID for recipe-based foods
            ownerId: ownerId,
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

        // Save immediately so it's available for meal logging
        Task {
            do {
                try await saveCustomFood(newFood, ownerId: ownerId)
            } catch {
                print("Error saving custom food from recipe: \(error)")
            }
        }

        // Trigger background AI analysis to refine details
        let foodID = newFood.id
        let recipeTitle = recipe.title
        let recipeIngredients = recipe.ingredients

        Task { [weak self] in
            do {
                guard let self else { return }
                guard let aiService = self.aiServiceManager else { return }
                let details = try await aiService.analyzeRecipe(title: recipeTitle, ingredients: recipeIngredients)

                await MainActor.run {
                    if var foodToUpdate = self.customFoods.first(where: { $0.id == foodID }) {
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
                        // Merge AI-detected nutrients with existing ones (don't replace, add to them)
                        let aiNutrients = details.nutrients.compactMap { Nutrient(rawValue: $0) }
                        let mergedNutrients = Set(foodToUpdate.nutrients + aiNutrients)
                        foodToUpdate.nutrients = Array(mergedNutrients)

                        // Persist update
                        Task {
                            do {
                                try await self.saveCustomFood(foodToUpdate, ownerId: ownerId)
                            } catch {
                                print("Error updating custom food with AI details: \(error)")
                            }
                        }
                    }
                }
            } catch {
                print("Failed to analyze recipe: \(error)")
            }
        }

        return newFood
    }

    // MARK: - Meal Planning

    func addMealPlanEntry(_ entry: MealPlanEntry) {
        // Optimistic Update
        var optimisticEntry = entry
        let entryId = optimisticEntry.id ?? UUID().uuidString
        optimisticEntry.id = entryId

        // Update local state immediately
        mealPlanEntries.append(optimisticEntry)

        // Perform Firestore save - now properly async
        Task {
            do {
                // Use the ID generated locally to ensure consistency
                try await self.mealPlanService.add(optimisticEntry, withId: entryId)
            } catch {
                print("Error saving meal plan entry: \(error)")
                // Rollback on failure
                await MainActor.run {
                    if let index = self.mealPlanEntries.firstIndex(where: { $0.id == entryId }) {
                        self.mealPlanEntries.remove(at: index)
                    }
                }
            }
        }
    }

    func deleteMealPlanEntry(_ entry: MealPlanEntry) {
        guard let id = entry.id else { return }

        // Optimistic Update - remove immediately
        if let index = mealPlanEntries.firstIndex(where: { $0.id == id }) {
            let removedEntry = mealPlanEntries.remove(at: index)

            // Perform Firestore delete
            Task {
                do {
                    try await self.mealPlanService.delete(id: id)
                } catch {
                    print("Error deleting meal plan entry: \(error)")
                    // Rollback on failure - add it back
                    await MainActor.run {
                        self.mealPlanEntries.append(removedEntry)
                    }
                }
            }
        }
    }

    func getMealPlanEntries(for date: Date) -> [MealType: [MealPlanEntry]] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return [:]
        }

        let entries = mealPlanEntries.filter { entry in
            entry.date >= dayStart && entry.date < dayEnd
        }

        var result: [MealType: [MealPlanEntry]] = [:]
        for entry in entries {
            if result[entry.mealType] == nil {
                result[entry.mealType] = []
            }
            result[entry.mealType]?.append(entry)
        }

        // Sort each meal type's entries by sortOrder
        for mealType in result.keys {
            result[mealType]?.sort { $0.sortOrder < $1.sortOrder }
        }

        return result
    }

    // MARK: - Shopping List

    func addShoppingListItem(_ item: ShoppingListItem) async throws {
        // Optimistic Update
        var optimisticItem = item
        if optimisticItem.id == nil {
            optimisticItem.id = UUID().uuidString
        }

        // Update local state immediately
        ownedShoppingItems.append(optimisticItem)
        mergeShoppingItems()

        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(optimisticItem) {
                let operation = QueuedOperation(
                    type: .shoppingListItem,
                    payload: encoded,
                    priority: .low
                )
                OfflineQueue.shared.enqueue(operation)
                // Return success for offline mode so UI stays updated
                return
            }
            throw FirebaseError.networkUnavailable
        }

        // Perform Firestore save - now properly async
        do {
            if let id = optimisticItem.id {
                try await self.shoppingListService.add(optimisticItem, withId: id)
            } else if item.id != nil {
                try await self.shoppingListService.update(item)
            } else {
                // Fallback (shouldn't happen with optimistic logic)
                try await self.shoppingListService.add(item)
            }
        } catch {
            // Rollback on failure
            if let index = self.ownedShoppingItems.firstIndex(where: { $0.id == optimisticItem.id }) {
                self.ownedShoppingItems.remove(at: index)
                self.mergeShoppingItems()
            }
            throw error
        }
    }

    func toggleShoppingItemComplete(_ item: ShoppingListItem) async throws {
        var updatedItem = item
        updatedItem.isCompleted.toggle()

        // Optimistic Update
        if let index = self.ownedShoppingItems.firstIndex(where: { $0.id == item.id }) {
            self.ownedShoppingItems[index] = updatedItem
            self.mergeShoppingItems()
        } else if let index = self.sharedShoppingItems.firstIndex(where: { $0.id == item.id }) {
            // If it's a shared item, update local cache too
            self.sharedShoppingItems[index] = updatedItem
            self.mergeShoppingItems()
        }

        guard NetworkMonitor.shared.isConnected else {
            // Queue update if offline
            if let encoded = try? JSONEncoder().encode(updatedItem) {
                let operation = QueuedOperation(
                    type: .shoppingListItem,
                    payload: encoded,
                    priority: .low
                )
                OfflineQueue.shared.enqueue(operation)
                return
            }
            throw FirebaseError.networkUnavailable
        }

        // Perform Firestore update - now properly async
        do {
            try await self.shoppingListService.update(updatedItem)
        } catch {
            // Rollback on failure
            if let index = self.ownedShoppingItems.firstIndex(where: { $0.id == item.id }) {
                self.ownedShoppingItems[index] = item // Revert to original
                self.mergeShoppingItems()
            } else if let index = self.sharedShoppingItems.firstIndex(where: { $0.id == item.id }) {
                self.sharedShoppingItems[index] = item
                self.mergeShoppingItems()
            }
            throw error
        }
    }

    func deleteShoppingListItem(_ item: ShoppingListItem) {
        guard let id = item.id else { return }

        // Optimistic Update - remove immediately
        if let index = ownedShoppingItems.firstIndex(where: { $0.id == id }) {
            let removedItem = ownedShoppingItems.remove(at: index)
            mergeShoppingItems()

            // Perform Firestore delete
            Task {
                do {
                    try await self.shoppingListService.delete(id: id)
                } catch {
                    print("Error deleting shopping list item: \(error)")
                    // Rollback on failure
                    await MainActor.run {
                        self.ownedShoppingItems.append(removedItem)
                        self.mergeShoppingItems()
                    }
                }
            }
        } else if let index = sharedShoppingItems.firstIndex(where: { $0.id == id }) {
            let removedItem = sharedShoppingItems.remove(at: index)
            mergeShoppingItems()

            // Perform Firestore delete
            Task {
                do {
                    try await self.shoppingListService.delete(id: id)
                } catch {
                    print("Error deleting shopping list item: \(error)")
                    // Rollback on failure
                    await MainActor.run {
                        self.sharedShoppingItems.append(removedItem)
                        self.mergeShoppingItems()
                    }
                }
            }
        }
    }

    func generateShoppingListFromMealPlan(ownerId: String) {
        // Clear existing recipe-sourced items
        let recipeItems = shoppingListItems.filter { $0.source == .recipe }
        for item in recipeItems {
            deleteShoppingListItem(item)
        }

        // Get all unique recipes from meal plan
        let recipeIds = Set(mealPlanEntries.map { $0.recipeId })
        let plannedRecipes = recipes.filter { 
            guard let id = $0.id else { return false }
            return recipeIds.contains(id) 
        }

        // Extract and parse ingredients
        var parsedItems: [ShoppingListItem] = []
        for recipe in plannedRecipes {
            for ingredient in recipe.parsedIngredients {
                let parsed = parseIngredient(ingredient)
                let category = categorizeIngredient(parsed.name)
                let item = ShoppingListItem(
                    ownerId: ownerId,
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
        Task {
            for item in consolidatedItems {
                try? await addShoppingListItem(item)
            }
        }
    }
    
    // MARK: - Ingredient Parsing Helpers (Unchanged)
    
    func parseIngredient(_ ingredient: String) -> (quantity: String?, unit: String?, name: String) {
        let trimmed = ingredient.trimmingCharacters(in: .whitespaces)
        
        let units = ["cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
                     "oz", "ounce", "ounces", "lb", "lbs", "pound", "pounds", "g", "gram", "grams",
                     "kg", "kilogram", "kilograms", "ml", "milliliter", "milliliters", "l", "liter", "liters",
                     "clove", "cloves", "bunch", "bunches", "can", "cans", "package", "packages",
                     "slice", "slices", "piece", "pieces", "pinch", "dash"]
        
        let components = trimmed.components(separatedBy: " ")
        guard components.count >= 2 else {
            return (nil, nil, trimmed)
        }
        
        var quantity: String?
        var unit: String?
        var nameStartIndex = 0
        
        let firstComponent = components[0]
        if firstComponent.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789/.-")) != nil {
            quantity = firstComponent
            nameStartIndex = 1
            
            if components.count > 1 {
                let secondComponent = components[1].lowercased()
                if units.contains(where: { secondComponent.hasPrefix($0) }) {
                    unit = components[1]
                    nameStartIndex = 2
                }
            }
        }
        
        let name = components[nameStartIndex...].joined(separator: " ")
        return (quantity, unit, name.isEmpty ? trimmed : name)
    }
    
    func categorizeIngredient(_ name: String) -> GroceryCategory {
        let lowercased = name.lowercased()
        
        let produceKeywords = ["lettuce", "tomato", "onion", "garlic", "carrot", "celery", "pepper", "spinach",
                               "kale", "broccoli", "cauliflower", "cucumber", "zucchini", "squash", "potato",
                               "apple", "banana", "orange", "lemon", "lime", "berry", "berries", "avocado",
                               "mushroom", "herb", "parsley", "cilantro", "basil", "thyme", "rosemary"]
        
        let dairyKeywords = ["milk", "cream", "cheese", "butter", "yogurt", "egg", "eggs", "sour cream",
                            "cottage cheese", "cheddar", "mozzarella", "parmesan"]
        
        let meatKeywords = ["chicken", "beef", "pork", "turkey", "lamb", "fish", "salmon", "tuna",
                           "shrimp", "meat", "bacon", "sausage", "ground beef", "steak"]
        
        let pantryKeywords = ["flour", "sugar", "salt", "pepper", "oil", "olive oil", "vinegar", "rice",
                             "pasta", "noodle", "bean", "beans", "lentil", "quinoa", "oat", "cereal",
                             "sauce", "stock", "broth", "can", "canned", "jar", "spice", "seasoning"]
        
        let frozenKeywords = ["frozen", "ice cream", "popsicle"]
        
        let bakeryKeywords = ["bread", "bun", "roll", "bagel", "tortilla", "pita", "croissant", "muffin"]
        
        let beverageKeywords = ["juice", "soda", "water", "tea", "coffee", "drink", "beverage"]
        
        if produceKeywords.contains(where: { lowercased.contains($0) }) { return .produce }
        else if dairyKeywords.contains(where: { lowercased.contains($0) }) { return .dairy }
        else if meatKeywords.contains(where: { lowercased.contains($0) }) { return .meatSeafood }
        else if frozenKeywords.contains(where: { lowercased.contains($0) }) { return .frozen }
        else if bakeryKeywords.contains(where: { lowercased.contains($0) }) { return .bakery }
        else if beverageKeywords.contains(where: { lowercased.contains($0) }) { return .beverages }
        else if pantryKeywords.contains(where: { lowercased.contains($0) }) { return .pantry }
        
        return .other
    }
    
    func consolidateShoppingItems(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
        var consolidated: [String: ShoppingListItem] = [:]
        
        for item in items {
            let key = item.name.lowercased()
            
            if let existing = consolidated[key] {
                if let existingQty = existing.quantity,
                   let newQty = item.quantity,
                   existing.unit == item.unit,
                   let existingNum = Double(existingQty),
                   let newNum = Double(newQty) {
                    let combined = existingNum + newNum
                    var updated = existing
                    updated.quantity = String(format: "%.1f", combined).replacingOccurrences(of: ".0", with: "")
                    consolidated[key] = updated
                } else if existing.quantity == nil && item.quantity != nil {
                     var updated = existing
                     updated.quantity = item.quantity
                     updated.unit = item.unit
                     consolidated[key] = updated
                }
            } else {
                consolidated[key] = item
            }
        }
        
        return Array(consolidated.values).sorted { $0.name < $1.name }
    }

    // MARK: - Data Loading

    func loadData(ownerId: String) {
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        // RECIPES - Owned
        listeners.append(
            recipeService.addListener(forUserId: ownerId) { [weak self] recipes in
                self?.ownedRecipes = recipes
                self?.mergeRecipes()
            }
        )

        // RECIPES - Shared
        listeners.append(
            db.collection("recipes")
                .whereField("sharedWith", arrayContains: ownerId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    self?.sharedRecipes = documents.compactMap { try? $0.data(as: Recipe.self) }
                    self?.mergeRecipes()
                }
        )

        // CUSTOM FOODS - Owned
        listeners.append(
            customFoodService.addListener(forUserId: ownerId) { [weak self] foods in
                self?.ownedCustomFoods = foods
                self?.mergeCustomFoods()
            }
        )

        // CUSTOM FOODS - Shared
        listeners.append(
            db.collection("custom_foods")
                .whereField("sharedWith", arrayContains: ownerId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    self?.sharedCustomFoods = documents.compactMap { try? $0.data(as: CustomFood.self) }
                    self?.mergeCustomFoods()
                }
        )

        // SHOPPING LIST - Owned
        listeners.append(
            shoppingListService.addListener(forUserId: ownerId) { [weak self] items in
                self?.ownedShoppingItems = items
                self?.mergeShoppingItems()
            }
        )

        // SHOPPING LIST - Shared
        listeners.append(
            db.collection("shopping_list_items")
                .whereField("sharedWith", arrayContains: ownerId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    self?.sharedShoppingItems = documents.compactMap { try? $0.data(as: ShoppingListItem.self) }
                    self?.mergeShoppingItems()
                }
        )

        // MEAL PLAN - Owned (no sharing for meal plan entries - they're child-specific)
        listeners.append(
            mealPlanService.addListener(forUserId: ownerId) { [weak self] entries in
                self?.mealPlanEntries = entries
            }
        )
    }

    // MARK: - Merge Functions

    private func mergeRecipes() {
        var all = [Recipe]()
        all.append(contentsOf: ownedRecipes)
        // Only add shared recipes that aren't already in owned
        for sharedRecipe in sharedRecipes {
            if !all.contains(where: { $0.id == sharedRecipe.id }) {
                all.append(sharedRecipe)
            }
        }
        recipes = all.sorted { $0.createdAt > $1.createdAt }
    }

    private func mergeCustomFoods() {
        var all = [CustomFood]()
        all.append(contentsOf: ownedCustomFoods)
        // Only add shared foods that aren't already in owned
        for sharedFood in sharedCustomFoods {
            if !all.contains(where: { $0.id == sharedFood.id }) {
                all.append(sharedFood)
            }
        }
        customFoods = all.sorted { $0.name < $1.name }
    }

    private func mergeShoppingItems() {
        var all = [ShoppingListItem]()
        all.append(contentsOf: ownedShoppingItems)
        // Only add shared items that aren't already in owned
        for sharedItem in sharedShoppingItems {
            if !all.contains(where: { $0.id == sharedItem.id }) {
                all.append(sharedItem)
            }
        }
        shoppingListItems = all.sorted { $0.createdAt > $1.createdAt }
    }
}
