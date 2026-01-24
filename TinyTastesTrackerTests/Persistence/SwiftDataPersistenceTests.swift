//
//  SwiftDataPersistenceTests.swift
//  TinyTastesTrackerTests
//
//  Comprehensive SwiftData persistence tests for all models
//

import XCTest
import SwiftData
@testable import TinyTastesTracker

final class SwiftDataPersistenceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory model container with all models
        let schema = Schema([
            UserProfile.self,
            Recipe.self,
            MealPlanEntry.self,
            ShoppingListItem.self,
            CustomFood.self,
            TriedFoodLog.self,
            MealLog.self,
            NursingLog.self,
            SleepLog.self,
            DiaperLog.self,
            BottleFeedLog.self,
            GrowthMeasurement.self,
            Milestone.self,
            Badge.self,
            NutrientGoals.self
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
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - UserProfile Persistence Tests

    func testUserProfilePersistence() throws {
        let profile = UserProfile(
            babyName: "Test Baby",
            birthDate: Date(),
            gender: .boy
        )

        modelContext.insert(profile)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.babyName, "Test Baby")
    }

    func testUserProfileUniqueConstraint() throws {
        let id = UUID()
        let profile1 = UserProfile(id: id, babyName: "Baby 1", birthDate: Date(), gender: .boy)
        let profile2 = UserProfile(id: id, babyName: "Baby 2", birthDate: Date(), gender: .girl)

        modelContext.insert(profile1)
        try modelContext.save()

        modelContext.insert(profile2)

        // SwiftData should handle unique constraint
        // Second profile with same ID should replace first or throw error
        do {
            try modelContext.save()
            // If save succeeds, check that only one profile exists
            let fetchDescriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(fetchDescriptor)
            XCTAssertLessThanOrEqual(profiles.count, 1)
        } catch {
            // Expected behavior - unique constraint violation
            XCTAssertTrue(true)
        }
    }

    func testUserProfileUpdate() throws {
        let profile = UserProfile(babyName: "Original Name", birthDate: Date(), gender: .boy)
        modelContext.insert(profile)
        try modelContext.save()

        // Update the profile
        profile.babyName = "Updated Name"
        profile.knownAllergies = ["Peanuts", "Dairy"]
        try modelContext.save()

        // Fetch and verify
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.babyName, "Updated Name")
        XCTAssertEqual(profiles.first?.knownAllergies, ["Peanuts", "Dairy"])
    }

    func testUserProfileDelete() throws {
        let profile = UserProfile(babyName: "Test Baby", birthDate: Date(), gender: .boy)
        modelContext.insert(profile)
        try modelContext.save()

        // Delete
        modelContext.delete(profile)
        try modelContext.save()

        // Verify deletion
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 0)
    }

    // MARK: - Recipe Persistence Tests

    func testRecipePersistence() throws {
        let recipe = Recipe(
            title: "Test Recipe",
            ingredients: "Ingredient 1, Ingredient 2",
            instructions: "Mix and cook",
            tags: ["breakfast", "healthy"]
        )

        modelContext.insert(recipe)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes.first?.title, "Test Recipe")
        XCTAssertEqual(recipes.first?.tags, ["breakfast", "healthy"])
    }

    func testRecipeWithImageData() throws {
        let imageData = Data([0x01, 0x02, 0x03, 0x04])
        let recipe = Recipe(
            title: "Image Recipe",
            ingredients: "Test",
            instructions: "Test",
            tags: [],
            imageData: imageData
        )

        modelContext.insert(recipe)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes.first?.imageData, imageData)
    }

    func testRecipeQuery() throws {
        let recipe1 = Recipe(title: "Breakfast Recipe", ingredients: "Eggs", instructions: "Cook", tags: ["breakfast"])
        let recipe2 = Recipe(title: "Lunch Recipe", ingredients: "Chicken", instructions: "Grill", tags: ["lunch"])
        let recipe3 = Recipe(title: "Another Breakfast", ingredients: "Oats", instructions: "Cook", tags: ["breakfast"])

        modelContext.insert(recipe1)
        modelContext.insert(recipe2)
        modelContext.insert(recipe3)
        try modelContext.save()

        // Query recipes with "Breakfast" in title
        let predicate = #Predicate<Recipe> { recipe in
            recipe.title.contains("Breakfast")
        }
        var fetchDescriptor = FetchDescriptor<Recipe>(predicate: predicate)
        let breakfastRecipes = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(breakfastRecipes.count, 2)
    }

    // MARK: - TriedFoodLog Persistence Tests

    func testTriedFoodLogPersistence() throws {
        let foodLog = TriedFoodLog(
            id: "APPLE",
            date: Date(),
            reaction: 5,
            meal: .breakfast
        )

        modelContext.insert(foodLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<TriedFoodLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.id, "APPLE")
        XCTAssertEqual(logs.first?.reaction, 5)
    }

    func testTriedFoodLogQuery() throws {
        let log1 = TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        let log2 = TriedFoodLog(id: "BANANA", date: Date(), reaction: 4, meal: .lunch)
        let log3 = TriedFoodLog(id: "BROCCOLI", date: Date(), reaction: 3, meal: .dinner)

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)
        try modelContext.save()

        // Query logs with reaction >= 4
        let predicate = #Predicate<TriedFoodLog> { log in
            log.reaction >= 4
        }
        let fetchDescriptor = FetchDescriptor<TriedFoodLog>(predicate: predicate)
        let goodReactionLogs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(goodReactionLogs.count, 2)
    }

    // MARK: - Newborn Log Persistence Tests

    func testNursingLogPersistence() throws {
        let nursingLog = NursingLog(
            timestamp: Date(),
            duration: 600,
            side: .left
        )

        modelContext.insert(nursingLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<NursingLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.side, .left)
        XCTAssertEqual(logs.first?.duration, 600)
    }

    func testSleepLogPersistence() throws {
        let start = Date()
        let end = start.addingTimeInterval(7200) // 2 hours

        let sleepLog = SleepLog(
            startTime: start,
            endTime: end,
            quality: .good
        )

        modelContext.insert(sleepLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<SleepLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.quality, .good)
        XCTAssertEqual(logs.first?.duration, 7200)
    }

    func testDiaperLogPersistence() throws {
        let diaperLog = DiaperLog(timestamp: Date(), type: .both)

        modelContext.insert(diaperLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<DiaperLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.type, .both)
    }

    func testBottleFeedLogPersistence() throws {
        let bottleLog = BottleFeedLog(
            timestamp: Date(),
            amount: 120.0,
            feedType: .breastMilk,
            notes: "Fed well"
        )

        modelContext.insert(bottleLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<BottleFeedLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.amount, 120.0)
        XCTAssertEqual(logs.first?.feedType, .breastMilk)
    }

    func testGrowthMeasurementPersistence() throws {
        let measurement = GrowthMeasurement(
            date: Date(),
            weight: 7.5,
            height: 60.0,
            headCircumference: 42.0,
            notes: "Regular checkup"
        )

        modelContext.insert(measurement)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<GrowthMeasurement>()
        let measurements = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(measurements.count, 1)
        XCTAssertEqual(measurements.first?.weight, 7.5)
        XCTAssertEqual(measurements.first?.height, 60.0)
    }

    // MARK: - Meal Planning Persistence Tests

    func testMealPlanEntryPersistence() throws {
        let entry = MealPlanEntry(
            date: Date(),
            mealType: .breakfast,
            recipeId: UUID()
        )

        modelContext.insert(entry)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<MealPlanEntry>()
        let entries = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.mealType, .breakfast)
    }

    func testShoppingListItemPersistence() throws {
        let item = ShoppingListItem(
            name: "Milk",
            quantity: "1",
            unit: "gallon",
            category: .dairy,
            source: .manual
        )

        modelContext.insert(item)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<ShoppingListItem>()
        let items = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Milk")
        XCTAssertEqual(items.first?.category, .dairy)
    }

    // MARK: - Batch Operations Tests

    func testBatchInsert() throws {
        var logs: [TriedFoodLog] = []
        for i in 0..<10 {
            let log = TriedFoodLog(
                id: "FOOD_\(i)",
                date: Date(),
                reaction: i % 5 + 1,
                meal: .breakfast
            )
            logs.append(log)
            modelContext.insert(log)
        }

        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<TriedFoodLog>()
        let savedLogs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(savedLogs.count, 10)
    }

    func testBatchDelete() throws {
        // Insert multiple items
        for i in 0..<5 {
            let log = DiaperLog(timestamp: Date(), type: .wet)
            modelContext.insert(log)
        }
        try modelContext.save()

        // Fetch and delete all
        let fetchDescriptor = FetchDescriptor<DiaperLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 5)

        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()

        // Verify deletion
        let remainingLogs = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(remainingLogs.count, 0)
    }

    // MARK: - Query with Sorting Tests

    func testQueryWithSorting() throws {
        let date1 = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        let date2 = Date().addingTimeInterval(-86400) // 1 day ago
        let date3 = Date() // today

        let recipe1 = Recipe(title: "Old Recipe", ingredients: "Test", instructions: "Test", tags: [], createdAt: date1)
        let recipe2 = Recipe(title: "Recent Recipe", ingredients: "Test", instructions: "Test", tags: [], createdAt: date2)
        let recipe3 = Recipe(title: "New Recipe", ingredients: "Test", instructions: "Test", tags: [], createdAt: date3)

        modelContext.insert(recipe1)
        modelContext.insert(recipe2)
        modelContext.insert(recipe3)
        try modelContext.save()

        // Fetch with sorting
        var fetchDescriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sortedRecipes = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(sortedRecipes.count, 3)
        XCTAssertEqual(sortedRecipes[0].title, "New Recipe")
        XCTAssertEqual(sortedRecipes[1].title, "Recent Recipe")
        XCTAssertEqual(sortedRecipes[2].title, "Old Recipe")
    }

    // MARK: - Date Range Query Tests

    func testDateRangeQuery() throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-86400 * 2)

        let log1 = TriedFoodLog(id: "FOOD1", date: twoDaysAgo, reaction: 5, meal: .breakfast)
        let log2 = TriedFoodLog(id: "FOOD2", date: yesterday, reaction: 4, meal: .lunch)
        let log3 = TriedFoodLog(id: "FOOD3", date: now, reaction: 3, meal: .dinner)

        modelContext.insert(log1)
        modelContext.insert(log2)
        modelContext.insert(log3)
        try modelContext.save()

        // Query logs from last 24 hours
        let oneDayAgo = now.addingTimeInterval(-86400)
        let predicate = #Predicate<TriedFoodLog> { log in
            log.date >= oneDayAgo
        }
        let fetchDescriptor = FetchDescriptor<TriedFoodLog>(predicate: predicate)
        let recentLogs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(recentLogs.count, 2) // Should get yesterday and today
    }

    // MARK: - Transaction Tests

    func testTransactionRollback() throws {
        let profile = UserProfile(babyName: "Test", birthDate: Date(), gender: .boy)
        modelContext.insert(profile)
        try modelContext.save()

        // Make a change but don't save
        profile.babyName = "Changed Name"

        // Rollback by creating new context
        let newContext = ModelContext(modelContainer)
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try newContext.fetch(fetchDescriptor)

        // Should still have original name
        XCTAssertEqual(profiles.first?.babyName, "Test")
    }

    // MARK: - Custom Food Persistence Tests

    func testCustomFoodPersistence() throws {
        let customFood = CustomFood(
            id: "CUSTOM_1",
            name: "Custom Food",
            emoji: "🍎",
            category: .fruits,
            allergens: ["Tree Nuts"],
            nutritionHighlights: "High in fiber",
            howToServe: "Slice thinly",
            chokeHazard: false,
            color: .red
        )

        modelContext.insert(customFood)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<CustomFood>()
        let foods = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(foods.count, 1)
        XCTAssertEqual(foods.first?.name, "Custom Food")
        XCTAssertEqual(foods.first?.allergens, ["Tree Nuts"])
    }

    // MARK: - Meal Log Persistence Tests

    func testMealLogPersistence() throws {
        let mealLog = MealLog(
            timestamp: Date(),
            mealType: .lunch,
            foods: ["APPLE", "BANANA", "CHICKEN"],
            notes: "Ate well"
        )

        modelContext.insert(mealLog)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<MealLog>()
        let logs = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.foods.count, 3)
        XCTAssertEqual(logs.first?.mealType, .lunch)
    }

    // MARK: - Complex Query Tests

    func testComplexQuery() throws {
        // Insert various sleep logs
        let goodSleep1 = SleepLog(startTime: Date().addingTimeInterval(-7200), endTime: Date(), quality: .excellent)
        let goodSleep2 = SleepLog(startTime: Date().addingTimeInterval(-7200), endTime: Date(), quality: .good)
        let poorSleep = SleepLog(startTime: Date().addingTimeInterval(-3600), endTime: Date(), quality: .poor)

        modelContext.insert(goodSleep1)
        modelContext.insert(goodSleep2)
        modelContext.insert(poorSleep)
        try modelContext.save()

        // Query: sleep duration > 1 hour AND quality is good or excellent
        let predicate = #Predicate<SleepLog> { log in
            log.duration > 3600 && (log.quality == .excellent || log.quality == .good)
        }
        let fetchDescriptor = FetchDescriptor<SleepLog>(predicate: predicate)
        let qualitySleep = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(qualitySleep.count, 2)
    }
}
