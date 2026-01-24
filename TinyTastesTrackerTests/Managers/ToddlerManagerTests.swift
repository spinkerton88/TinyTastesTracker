//
//  ToddlerManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for ToddlerManager business logic
//

import XCTest
import SwiftData
@testable import TinyTastesTracker

final class ToddlerManagerTests: XCTestCase {

    var manager: ToddlerManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testFoods: [FoodItem]!

    override func setUp() {
        super.setUp()
        manager = ToddlerManager()

        // Create in-memory model container for testing
        let schema = Schema([
            TriedFoodLog.self,
            MealLog.self,
            NutrientGoals.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Create test foods
        testFoods = [
            FoodItem(
                id: "APPLE",
                name: "Apple",
                emoji: "🍎",
                category: .fruits,
                allergens: [],
                nutritionHighlights: "Vitamin C",
                howToServe: "Slice thinly",
                chokeHazard: false,
                color: .red
            ),
            FoodItem(
                id: "BANANA",
                name: "Banana",
                emoji: "🍌",
                category: .fruits,
                allergens: [],
                nutritionHighlights: "Potassium",
                howToServe: "Mash or slice",
                chokeHazard: false,
                color: .yellow
            ),
            FoodItem(
                id: "BROCCOLI",
                name: "Broccoli",
                emoji: "🥦",
                category: .vegetables,
                allergens: [],
                nutritionHighlights: "Iron",
                howToServe: "Steam until soft",
                chokeHazard: false,
                color: .green
            ),
            FoodItem(
                id: "CHICKEN",
                name: "Chicken",
                emoji: "🍗",
                category: .proteins,
                allergens: [],
                nutritionHighlights: "Protein",
                howToServe: "Cut into small pieces",
                chokeHazard: false,
                color: .brown
            )
        ]

        manager.updateKnownFoods(testFoods)
    }

    override func tearDown() {
        manager = nil
        modelContext = nil
        modelContainer = nil
        testFoods = nil
        super.tearDown()
    }

    // MARK: - Food Tracking Tests

    func testTriedFoodsCountEmpty() {
        XCTAssertEqual(manager.triedFoodsCount, 0)
    }

    func testTriedFoodsCountWithLogs() {
        let log1 = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        let log2 = TriedFoodLog(id: "BANANA", date: Date(), reaction: 4, meal: .lunch)

        manager.saveFoodLog(log1, context: modelContext)
        manager.saveFoodLog(log2, context: modelContext)

        XCTAssertEqual(manager.triedFoodsCount, 2)
    }

    func testTriedFoodsCountWithDuplicates() {
        let log1 = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        let log2 = TriedFoodLog(id: "APPLE", date: Date().addingTimeInterval(3600), reaction: 4, meal: .lunch)

        manager.saveFoodLog(log1, context: modelContext)
        manager.saveFoodLog(log2, context: modelContext)

        // Should count unique foods only
        XCTAssertEqual(manager.triedFoodsCount, 1)
    }

    func testIsFoodTriedReturnsFalseForUntriedFood() {
        XCTAssertFalse(manager.isFoodTried("APPLE"))
    }

    func testIsFoodTriedReturnsTrueForTriedFood() {
        let log = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(log, context: modelContext)

        XCTAssertTrue(manager.isFoodTried("APPLE"))
    }

    func testSaveFoodLogAddsNewLog() {
        let log = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(log, context: modelContext)

        XCTAssertEqual(manager.foodLogs.count, 1)
        XCTAssertEqual(manager.foodLogs.first?.id, "APPLE")
    }

    func testSaveFoodLogUpdatesExistingLog() {
        let log1 = TriedFoodLog(id: "APPLE", date: Date(), reaction: 3, meal: .breakfast)
        manager.saveFoodLog(log1, context: modelContext)

        let log2 = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .lunch)
        manager.saveFoodLog(log2, context: modelContext)

        XCTAssertEqual(manager.foodLogs.count, 1)
        XCTAssertEqual(manager.foodLogs.first?.reaction, 5)
        XCTAssertEqual(manager.foodLogs.first?.meal, .lunch)
    }

    // MARK: - Meal Logging Tests

    func testSaveMealLog() {
        let mealLog = MealLog(
            timestamp: Date(),
            mealType: .breakfast,
            foods: ["APPLE", "BANANA"],
            notes: "Ate well"
        )

        manager.saveMealLog(mealLog, context: modelContext)

        XCTAssertEqual(manager.mealLogs.count, 1)
        XCTAssertEqual(manager.mealLogs.first?.foods, ["APPLE", "BANANA"])
    }

    func testSaveMealLogAutoAddsFoodLogs() {
        let mealLog = MealLog(
            timestamp: Date(),
            mealType: .lunch,
            foods: ["BROCCOLI", "CHICKEN"],
            notes: nil
        )

        manager.saveMealLog(mealLog, context: modelContext)

        XCTAssertEqual(manager.mealLogs.count, 1)
        // Should automatically create food logs for untried foods
        XCTAssertTrue(manager.isFoodTried("BROCCOLI"))
        XCTAssertTrue(manager.isFoodTried("CHICKEN"))
    }

    func testSaveMealLogDoesNotDuplicateFoodLogs() {
        // First, manually log apple
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(appleLog, context: modelContext)

        // Now log a meal with apple and banana
        let mealLog = MealLog(
            timestamp: Date(),
            mealType: .lunch,
            foods: ["APPLE", "BANANA"],
            notes: nil
        )

        manager.saveMealLog(mealLog, context: modelContext)

        // Should only have 2 food logs (apple already existed, banana is new)
        XCTAssertEqual(manager.triedFoodsCount, 2)
    }

    // MARK: - Food Filtering Tests

    func testFilteredFoodsNoFilters() {
        let filtered = manager.filteredFoods(
            searchText: "",
            category: nil,
            showOnlyTried: nil,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 4)
    }

    func testFilteredFoodsByCategory() {
        let filtered = manager.filteredFoods(
            searchText: "",
            category: .fruits,
            showOnlyTried: nil,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.category == .fruits })
    }

    func testFilteredFoodsBySearchText() {
        let filtered = manager.filteredFoods(
            searchText: "app",
            category: nil,
            showOnlyTried: nil,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Apple")
    }

    func testFilteredFoodsShowOnlyTried() {
        // Mark some foods as tried
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(appleLog, context: modelContext)

        let filtered = manager.filteredFoods(
            searchText: "",
            category: nil,
            showOnlyTried: true,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "APPLE")
    }

    func testFilteredFoodsShowOnlyUntried() {
        // Mark some foods as tried
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(appleLog, context: modelContext)

        let filtered = manager.filteredFoods(
            searchText: "",
            category: nil,
            showOnlyTried: false,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 3)
        XCTAssertFalse(filtered.contains { $0.id == "APPLE" })
    }

    func testFilteredFoodsCombinedFilters() {
        // Mark apple as tried
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(appleLog, context: modelContext)

        let filtered = manager.filteredFoods(
            searchText: "a",
            category: .fruits,
            showOnlyTried: true,
            from: testFoods
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "APPLE")
    }

    // MARK: - Category Progress Tests

    func testCategoryProgressNoTriedFoods() {
        let progress = manager.categoryProgress(.fruits)

        XCTAssertEqual(progress.tried, 0)
        XCTAssertEqual(progress.total, 2)
    }

    func testCategoryProgressWithTriedFoods() {
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        manager.saveFoodLog(appleLog, context: modelContext)

        let progress = manager.categoryProgress(.fruits)

        XCTAssertEqual(progress.tried, 1)
        XCTAssertEqual(progress.total, 2)
    }

    func testCategoryProgressAllFoodsTried() {
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        let bananaLog = TriedFoodLog(id: "BANANA", date: Date(), reaction: 4, meal: .lunch)
        manager.saveFoodLog(appleLog, context: modelContext)
        manager.saveFoodLog(bananaLog, context: modelContext)

        let progress = manager.categoryProgress(.fruits)

        XCTAssertEqual(progress.tried, 2)
        XCTAssertEqual(progress.total, 2)
    }

    func testCategoryProgressForDifferentCategories() {
        let appleLog = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        let broccoliLog = TriedFoodLog(id: "BROCCOLI", date: Date(), reaction: 4, meal: .lunch)
        manager.saveFoodLog(appleLog, context: modelContext)
        manager.saveFoodLog(broccoliLog, context: modelContext)

        let fruitsProgress = manager.categoryProgress(.fruits)
        let vegetablesProgress = manager.categoryProgress(.vegetables)

        XCTAssertEqual(fruitsProgress.tried, 1)
        XCTAssertEqual(fruitsProgress.total, 2)
        XCTAssertEqual(vegetablesProgress.tried, 1)
        XCTAssertEqual(vegetablesProgress.total, 1)
    }

    // MARK: - Known Foods Tests

    func testUpdateKnownFoods() {
        let newFoods = [
            FoodItem(
                id: "ORANGE",
                name: "Orange",
                emoji: "🍊",
                category: .fruits,
                allergens: [],
                nutritionHighlights: "Vitamin C",
                howToServe: "Peel and segment",
                chokeHazard: false,
                color: .orange
            )
        ]

        manager.updateKnownFoods(newFoods)

        XCTAssertEqual(manager.allKnownFoods.count, 1)
        XCTAssertEqual(manager.allKnownFoods.first?.id, "ORANGE")
    }
}
