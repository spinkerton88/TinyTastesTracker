//
//  RecipeManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for RecipeManager business logic
//

import XCTest
import SwiftData
@testable import TinyTastesTracker

final class RecipeManagerTests: XCTestCase {

    var manager: RecipeManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        manager = RecipeManager()

        // Create in-memory model container for testing
        let schema = Schema([
            Recipe.self,
            MealPlanEntry.self,
            ShoppingListItem.self,
            CustomFood.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    override func tearDown() {
        manager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Recipe Management Tests

    func testSaveRecipe() {
        let recipe = Recipe(
            title: "Test Recipe",
            ingredients: "2 cups flour, 1 egg",
            instructions: "Mix and bake",
            tags: ["breakfast"]
        )

        manager.saveRecipe(recipe, context: modelContext)

        XCTAssertEqual(manager.recipes.count, 1)
        XCTAssertEqual(manager.recipes.first?.title, "Test Recipe")
    }

    func testDeleteRecipe() {
        let recipe = Recipe(
            title: "Test Recipe",
            ingredients: "Flour, Eggs",
            instructions: "Mix",
            tags: []
        )

        manager.saveRecipe(recipe, context: modelContext)
        XCTAssertEqual(manager.recipes.count, 1)

        manager.deleteRecipe(recipe, context: modelContext)
        XCTAssertEqual(manager.recipes.count, 0)
    }

    // MARK: - Meal Planning Tests

    func testAddMealPlanEntry() {
        let recipe = Recipe(
            title: "Breakfast Recipe",
            ingredients: "Oats, Banana",
            instructions: "Cook",
            tags: ["breakfast"]
        )

        let entry = MealPlanEntry(
            date: Date(),
            mealType: .breakfast,
            recipeId: recipe.id
        )

        manager.addMealPlanEntry(entry, context: modelContext)

        XCTAssertEqual(manager.mealPlanEntries.count, 1)
        XCTAssertEqual(manager.mealPlanEntries.first?.mealType, .breakfast)
    }

    func testRemoveMealPlanEntry() {
        let entry = MealPlanEntry(
            date: Date(),
            mealType: .lunch,
            recipeId: UUID()
        )

        manager.addMealPlanEntry(entry, context: modelContext)
        XCTAssertEqual(manager.mealPlanEntries.count, 1)

        manager.removeMealPlanEntry(entry, context: modelContext)
        XCTAssertEqual(manager.mealPlanEntries.count, 0)
    }

    func testGetMealPlanEntriesForDate() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let breakfastEntry = MealPlanEntry(
            date: today,
            mealType: .breakfast,
            recipeId: UUID()
        )

        let lunchEntry = MealPlanEntry(
            date: today,
            mealType: .lunch,
            recipeId: UUID()
        )

        let tomorrowEntry = MealPlanEntry(
            date: tomorrow,
            mealType: .breakfast,
            recipeId: UUID()
        )

        manager.addMealPlanEntry(breakfastEntry, context: modelContext)
        manager.addMealPlanEntry(lunchEntry, context: modelContext)
        manager.addMealPlanEntry(tomorrowEntry, context: modelContext)

        let todayEntries = manager.getMealPlanEntries(for: today)

        XCTAssertEqual(todayEntries.count, 2)
        XCTAssertNotNil(todayEntries[.breakfast])
        XCTAssertNotNil(todayEntries[.lunch])
        XCTAssertNil(todayEntries[.dinner])
    }

    // MARK: - Shopping List Tests

    func testAddShoppingListItem() {
        let item = ShoppingListItem(
            name: "Bananas",
            quantity: "3",
            unit: nil,
            category: .produce,
            source: .manual
        )

        manager.addShoppingListItem(item, context: modelContext)

        XCTAssertEqual(manager.shoppingListItems.count, 1)
        XCTAssertEqual(manager.shoppingListItems.first?.name, "Bananas")
        XCTAssertEqual(manager.shoppingListItems.first?.category, .produce)
    }

    func testToggleShoppingItemComplete() {
        let item = ShoppingListItem(
            name: "Milk",
            quantity: "1",
            unit: "gallon",
            category: .dairy,
            source: .manual
        )

        manager.addShoppingListItem(item, context: modelContext)
        XCTAssertFalse(item.isCompleted)

        manager.toggleShoppingItemComplete(item)
        XCTAssertTrue(item.isCompleted)

        manager.toggleShoppingItemComplete(item)
        XCTAssertFalse(item.isCompleted)
    }

    func testRemoveShoppingListItem() {
        let item = ShoppingListItem(
            name: "Bread",
            quantity: nil,
            unit: nil,
            category: .bakery,
            source: .manual
        )

        manager.addShoppingListItem(item, context: modelContext)
        XCTAssertEqual(manager.shoppingListItems.count, 1)

        manager.removeShoppingListItem(item, context: modelContext)
        XCTAssertEqual(manager.shoppingListItems.count, 0)
    }

    // MARK: - Ingredient Parsing Tests

    func testParseIngredientWithQuantityAndUnit() {
        let result = manager.parseIngredient("2 cups flour")

        XCTAssertEqual(result.quantity, "2")
        XCTAssertEqual(result.unit, "cups")
        XCTAssertEqual(result.name, "flour")
    }

    func testParseIngredientWithQuantityOnly() {
        let result = manager.parseIngredient("3 eggs")

        XCTAssertEqual(result.quantity, "3")
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "eggs")
    }

    func testParseIngredientWithFraction() {
        let result = manager.parseIngredient("1/2 cup milk")

        XCTAssertEqual(result.quantity, "1/2")
        XCTAssertEqual(result.unit, "cup")
        XCTAssertEqual(result.name, "milk")
    }

    func testParseIngredientWithDecimal() {
        let result = manager.parseIngredient("1.5 tablespoons olive oil")

        XCTAssertEqual(result.quantity, "1.5")
        XCTAssertEqual(result.unit, "tablespoons")
        XCTAssertEqual(result.name, "olive oil")
    }

    func testParseIngredientWithMultipleWords() {
        let result = manager.parseIngredient("2 cups all-purpose flour")

        XCTAssertEqual(result.quantity, "2")
        XCTAssertEqual(result.unit, "cups")
        XCTAssertEqual(result.name, "all-purpose flour")
    }

    func testParseIngredientWithoutQuantity() {
        let result = manager.parseIngredient("Salt to taste")

        XCTAssertNil(result.quantity)
        XCTAssertNil(result.unit)
        XCTAssertEqual(result.name, "Salt to taste")
    }

    func testParseIngredientWithPinch() {
        let result = manager.parseIngredient("1 pinch salt")

        XCTAssertEqual(result.quantity, "1")
        XCTAssertEqual(result.unit, "pinch")
        XCTAssertEqual(result.name, "salt")
    }

    // MARK: - Ingredient Categorization Tests

    func testCategorizeProduceIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("tomato"), .produce)
        XCTAssertEqual(manager.categorizeIngredient("spinach"), .produce)
        XCTAssertEqual(manager.categorizeIngredient("fresh carrots"), .produce)
        XCTAssertEqual(manager.categorizeIngredient("apple"), .produce)
    }

    func testCategorizeDairyIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("milk"), .dairy)
        XCTAssertEqual(manager.categorizeIngredient("cheese"), .dairy)
        XCTAssertEqual(manager.categorizeIngredient("yogurt"), .dairy)
        XCTAssertEqual(manager.categorizeIngredient("butter"), .dairy)
    }

    func testCategorizeMeatIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("chicken breast"), .meat)
        XCTAssertEqual(manager.categorizeIngredient("ground beef"), .meat)
        XCTAssertEqual(manager.categorizeIngredient("salmon"), .meat)
        XCTAssertEqual(manager.categorizeIngredient("pork chop"), .meat)
    }

    func testCategorizePantryIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("flour"), .pantry)
        XCTAssertEqual(manager.categorizeIngredient("sugar"), .pantry)
        XCTAssertEqual(manager.categorizeIngredient("olive oil"), .pantry)
        XCTAssertEqual(manager.categorizeIngredient("rice"), .pantry)
    }

    func testCategorizeFrozenIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("frozen peas"), .frozen)
        XCTAssertEqual(manager.categorizeIngredient("ice cream"), .frozen)
    }

    func testCategorizeBakeryIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("bread"), .bakery)
        XCTAssertEqual(manager.categorizeIngredient("bagels"), .bakery)
        XCTAssertEqual(manager.categorizeIngredient("rolls"), .bakery)
    }

    func testCategorizeBeverageIngredients() {
        XCTAssertEqual(manager.categorizeIngredient("orange juice"), .beverages)
        XCTAssertEqual(manager.categorizeIngredient("coffee"), .beverages)
        XCTAssertEqual(manager.categorizeIngredient("tea"), .beverages)
    }

    func testCategorizeUnknownIngredient() {
        XCTAssertEqual(manager.categorizeIngredient("mystery ingredient"), .other)
    }

    // MARK: - Custom Foods Tests

    func testSaveNewCustomFood() {
        let food = CustomFood(
            id: "CUSTOM_1",
            name: "Test Food",
            emoji: "🍎",
            category: .fruits,
            allergens: [],
            nutritionHighlights: "High in vitamin C",
            howToServe: "Slice thinly",
            chokeHazard: false,
            color: .red
        )

        manager.saveCustomFood(food, context: modelContext)

        XCTAssertEqual(manager.customFoods.count, 1)
        XCTAssertEqual(manager.customFoods.first?.name, "Test Food")
    }

    func testSaveExistingCustomFoodUpdates() {
        let food = CustomFood(
            id: "CUSTOM_1",
            name: "Original Name",
            emoji: "🍎",
            category: .fruits,
            allergens: [],
            nutritionHighlights: "Test",
            howToServe: "Test",
            chokeHazard: false,
            color: .red
        )

        manager.saveCustomFood(food, context: modelContext)
        XCTAssertEqual(manager.customFoods.count, 1)

        // Update the food
        let updatedFood = CustomFood(
            id: "CUSTOM_1",
            name: "Updated Name",
            emoji: "🍊",
            category: .fruits,
            allergens: [],
            nutritionHighlights: "Updated",
            howToServe: "Updated",
            chokeHazard: false,
            color: .orange
        )

        manager.saveCustomFood(updatedFood, context: modelContext)

        XCTAssertEqual(manager.customFoods.count, 1)
        XCTAssertEqual(manager.customFoods.first?.name, "Updated Name")
        XCTAssertEqual(manager.customFoods.first?.emoji, "🍊")
    }

    // MARK: - Pagination Tests

    func testPaginationDefaults() {
        XCTAssertEqual(manager.recipesOffset, 0)
        XCTAssertEqual(manager.recipesPageSize, 20)
        XCTAssertTrue(manager.hasMoreRecipes)
        XCTAssertEqual(manager.totalRecipeCount, 0)
    }
}
