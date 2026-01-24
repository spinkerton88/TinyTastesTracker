//
//  GeminiServiceIntegrationTests.swift
//  TinyTastesTrackerTests
//
//  Integration tests for AI-dependent features using mocks
//

import XCTest
import SwiftData
@testable import TinyTastesTracker

final class GeminiServiceIntegrationTests: XCTestCase {

    var mockGeminiService: MockGeminiService!

    override func setUp() {
        super.setUp()
        mockGeminiService = MockGeminiService()
    }

    override func tearDown() {
        mockGeminiService = nil
        super.tearDown()
    }

    // MARK: - Food Identification Tests

    func testIdentifyFoodFromImageSuccess() async throws {
        mockGeminiService.mockIdentifyFoodResult = "Banana"

        let image = UIImage(systemName: "photo")!
        let result = try await mockGeminiService.identifyFoodFromImage(image)

        XCTAssertEqual(result, "Banana")
        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 1)
    }

    func testIdentifyFoodFromImageError() async {
        mockGeminiService.shouldThrowError = true
        mockGeminiService.mockError = GeminiError.invalidResponse

        let image = UIImage(systemName: "photo")!

        do {
            _ = try await mockGeminiService.identifyFoodFromImage(image)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GeminiError)
        }
    }

    // MARK: - Recipe Generation Tests

    func testSuggestRecipeSuccess() async throws {
        let expectedRecipe = Recipe(
            title: "Banana Pancakes",
            ingredients: "Banana, Flour, Eggs",
            instructions: "Mix and cook",
            tags: ["breakfast"]
        )
        mockGeminiService.mockRecipe = expectedRecipe

        let ingredients = ["Banana", "Flour", "Eggs"]
        let result = try await mockGeminiService.suggestRecipe(ingredients: ingredients, ageInMonths: 12)

        XCTAssertEqual(result.title, expectedRecipe.title)
        XCTAssertEqual(result.ingredients, expectedRecipe.ingredients)
        XCTAssertEqual(mockGeminiService.suggestRecipeCallCount, 1)
        XCTAssertEqual(mockGeminiService.lastSuggestRecipeIngredients, ingredients)
        XCTAssertEqual(mockGeminiService.lastSuggestRecipeAge, 12)
    }

    func testSuggestRecipeError() async {
        mockGeminiService.shouldThrowError = true

        do {
            _ = try await mockGeminiService.suggestRecipe(ingredients: ["Apple"], ageInMonths: 6)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GeminiError)
        }
    }

    // MARK: - Sage Assistant Tests

    func testAskSageAssistantSuccess() async throws {
        mockGeminiService.mockSageResponse = "Iron is important for brain development."

        let question = "Why is iron important?"
        let context = "Nutritional advice"
        let result = try await mockGeminiService.askSageAssistant(question: question, context: context)

        XCTAssertEqual(result, "Iron is important for brain development.")
        XCTAssertEqual(mockGeminiService.askSageAssistantCallCount, 1)
        XCTAssertEqual(mockGeminiService.lastSageQuestion, question)
        XCTAssertEqual(mockGeminiService.lastSageContext, context)
    }

    func testAskSageAssistantError() async {
        mockGeminiService.shouldThrowError = true

        do {
            _ = try await mockGeminiService.askSageAssistant(question: "Test", context: "Test")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GeminiError)
        }
    }

    // MARK: - Sleep Prediction Tests

    func testPredictSleepWindowSuccess() async throws {
        let expectedPrediction = SleepPredictionResponse(
            predictionStatus: "Ready",
            nextSweetSpotStart: "2:00 PM",
            nextSweetSpotEnd: "3:00 PM",
            confidence: "High",
            reasoning: "Based on recent patterns"
        )
        mockGeminiService.mockSleepPrediction = expectedPrediction

        let sleepLogs: [SleepLog] = []
        let result = try await mockGeminiService.predictSleepWindow(
            recentSleepLogs: sleepLogs,
            currentTime: Date(),
            lastWakeTime: nil,
            ageInMonths: 3
        )

        XCTAssertEqual(result.predictionStatus, "Ready")
        XCTAssertEqual(result.nextSweetSpotStart, "2:00 PM")
        XCTAssertEqual(mockGeminiService.predictSleepWindowCallCount, 1)
    }

    // MARK: - Picky Eater Strategy Tests

    func testGeneratePickyEaterStrategySuccess() async throws {
        let expectedStrategy = PickyEaterStrategyResponse(
            strategyType: "food-bridging",
            steps: ["Step 1", "Step 2", "Step 3"],
            estimatedWeeks: 3,
            explanation: "Gradually introduce the new food"
        )
        mockGeminiService.mockPickyEaterStrategy = expectedStrategy

        let result = try await mockGeminiService.generatePickyEaterStrategy(
            enemyFood: "Broccoli",
            safeFood: "Cheese",
            ageInMonths: 18
        )

        XCTAssertEqual(result.strategyType, "food-bridging")
        XCTAssertEqual(result.steps.count, 3)
        XCTAssertEqual(result.estimatedWeeks, 3)
        XCTAssertEqual(mockGeminiService.generatePickyEaterStrategyCallCount, 1)
    }

    // MARK: - Nutrient Suggestions Tests

    func testSuggestNutrientRichFoodsSuccess() async throws {
        let expectedSuggestions = [
            NutrientFoodSuggestion(
                foodName: "Spinach",
                foodEmoji: "🥬",
                reasoning: "Rich in iron",
                servingTip: "Steam and puree"
            ),
            NutrientFoodSuggestion(
                foodName: "Lentils",
                foodEmoji: "🫘",
                reasoning: "Also high in iron",
                servingTip: "Cook until soft"
            )
        ]
        mockGeminiService.mockNutrientSuggestions = expectedSuggestions

        let result = try await mockGeminiService.suggestNutrientRichFoods(
            nutrient: "Iron",
            ageInMonths: 8,
            triedFoodIds: ["APPLE", "BANANA"]
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].foodName, "Spinach")
        XCTAssertEqual(mockGeminiService.suggestNutrientRichFoodsCallCount, 1)
        XCTAssertEqual(mockGeminiService.lastNutrientRequested, "Iron")
    }

    // MARK: - Flavor Pairings Tests

    func testGenerateFlavorPairingsSuccess() async throws {
        let expectedPairings = FlavorPairingResponse(
            pairings: [
                FlavorPairing(
                    title: "Apple & Cinnamon",
                    description: "Classic combo",
                    whyItWorks: "Sweet meets spice",
                    ingredients: ["Apple", "Cinnamon"]
                )
            ],
            chefTips: "Use fresh ingredients"
        )
        mockGeminiService.mockFlavorPairings = expectedPairings

        let triedFoods: [TriedFoodLog] = [
            TriedFoodLog(id: "APPLE", date: Date(), reaction: 5, meal: .breakfast)
        ]

        let result = try await mockGeminiService.generateFlavorPairings(
            triedFoods: triedFoods,
            childName: "Test Baby"
        )

        XCTAssertEqual(result.pairings.count, 1)
        XCTAssertEqual(result.pairings[0].title, "Apple & Cinnamon")
        XCTAssertEqual(mockGeminiService.generateFlavorPairingsCallCount, 1)
    }

    // MARK: - Custom Food Analysis Tests

    func testAnalyzeCustomFoodSuccess() async throws {
        let expectedDetails = CustomFoodDetails(
            emoji: "🥑",
            category: "fruits",
            allergens: [],
            nutritionHighlights: "Healthy fats",
            howToServe: "Mash well",
            chokeHazard: false,
            color: "Green",
            containedColors: ["Green"],
            containedCategories: ["fruits"],
            nutrients: ["fats", "fiber"]
        )
        mockGeminiService.mockCustomFoodDetails = expectedDetails

        let result = try await mockGeminiService.analyzeCustomFood(name: "Avocado")

        XCTAssertEqual(result.emoji, "🥑")
        XCTAssertEqual(result.category, "fruits")
        XCTAssertEqual(mockGeminiService.analyzeCustomFoodCallCount, 1)
        XCTAssertEqual(mockGeminiService.lastCustomFoodName, "Avocado")
    }

    func testAnalyzePackageSuccess() async throws {
        let image = UIImage(systemName: "photo")!
        let result = try await mockGeminiService.analyzePackage(image: image)

        XCTAssertNotNil(result)
        XCTAssertEqual(mockGeminiService.analyzePackageCallCount, 1)
    }

    func testAnalyzeRecipeSuccess() async throws {
        let title = "Baby Oatmeal"
        let ingredients = "Oats, Milk, Banana"

        let result = try await mockGeminiService.analyzeRecipe(title: title, ingredients: ingredients)

        XCTAssertNotNil(result)
        XCTAssertEqual(mockGeminiService.analyzeRecipeCallCount, 1)
        XCTAssertEqual(mockGeminiService.lastAnalyzeRecipeTitle, title)
        XCTAssertEqual(mockGeminiService.lastAnalyzeRecipeIngredients, ingredients)
    }

    // MARK: - Mock Reset Tests

    func testMockReset() async throws {
        // Make some calls
        _ = try await mockGeminiService.identifyFoodFromImage(UIImage(systemName: "photo")!)
        _ = try await mockGeminiService.suggestRecipe(ingredients: ["Test"], ageInMonths: 6)

        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 1)
        XCTAssertEqual(mockGeminiService.suggestRecipeCallCount, 1)

        // Reset
        mockGeminiService.reset()

        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 0)
        XCTAssertEqual(mockGeminiService.suggestRecipeCallCount, 0)
        XCTAssertFalse(mockGeminiService.shouldThrowError)
        XCTAssertNil(mockGeminiService.lastSuggestRecipeIngredients)
    }

    // MARK: - Multiple Calls Tests

    func testMultipleCalls() async throws {
        // First call
        _ = try await mockGeminiService.identifyFoodFromImage(UIImage(systemName: "photo")!)
        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 1)

        // Second call
        _ = try await mockGeminiService.identifyFoodFromImage(UIImage(systemName: "photo")!)
        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 2)

        // Third call
        _ = try await mockGeminiService.identifyFoodFromImage(UIImage(systemName: "photo")!)
        XCTAssertEqual(mockGeminiService.identifyFoodFromImageCallCount, 3)
    }
}
