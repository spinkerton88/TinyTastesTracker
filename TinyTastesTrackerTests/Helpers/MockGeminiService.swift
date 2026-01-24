//
//  MockGeminiService.swift
//  TinyTastesTrackerTests
//
//  Mock implementation of GeminiService for testing
//

import Foundation
import UIKit
@testable import TinyTastesTracker

class MockGeminiService: GeminiService {

    // MARK: - Mock Control Properties

    var shouldThrowError = false
    var mockError: Error = GeminiError.invalidResponse

    // MARK: - Mock Return Values

    var mockIdentifyFoodResult = "Apple"
    var mockRecipe = Recipe(
        title: "Mock Recipe",
        ingredients: "Mock ingredients",
        instructions: "Mock instructions",
        tags: ["mock"]
    )
    var mockSageResponse = "This is a mock response from Sage."
    var mockSleepPrediction = SleepPredictionResponse(
        predictionStatus: "Ready",
        nextSweetSpotStart: "2:30 PM",
        nextSweetSpotEnd: "3:00 PM",
        confidence: "High",
        reasoning: "Mock reasoning"
    )
    var mockPickyEaterStrategy = PickyEaterStrategyResponse(
        strategyType: "food-bridging",
        steps: ["Step 1", "Step 2", "Step 3"],
        estimatedWeeks: 2,
        explanation: "Mock explanation"
    )
    var mockNutrientSuggestions: [NutrientFoodSuggestion] = [
        NutrientFoodSuggestion(
            foodName: "Spinach",
            foodEmoji: "🥬",
            reasoning: "High in iron",
            servingTip: "Steam and puree"
        )
    ]
    var mockFlavorPairings = FlavorPairingResponse(
        pairings: [
            FlavorPairing(
                title: "Sweet & Savory",
                description: "Mock pairing",
                whyItWorks: "Mock reason",
                ingredients: ["Apple", "Cheese"]
            )
        ],
        chefTips: "Mock tips"
    )
    var mockCustomFoodDetails = CustomFoodDetails(
        emoji: "🍎",
        category: "fruits",
        allergens: [],
        nutritionHighlights: "Vitamin C",
        howToServe: "Slice thinly",
        chokeHazard: false,
        color: "Red",
        containedColors: ["Red"],
        containedCategories: ["fruits"],
        nutrients: ["iron", "calcium"]
    )

    // MARK: - Call Tracking

    var identifyFoodFromImageCallCount = 0
    var suggestRecipeCallCount = 0
    var askSageAssistantCallCount = 0
    var predictSleepWindowCallCount = 0
    var generatePickyEaterStrategyCallCount = 0
    var suggestNutrientRichFoodsCallCount = 0
    var generateFlavorPairingsCallCount = 0
    var analyzeCustomFoodCallCount = 0
    var analyzePackageCallCount = 0
    var analyzeRecipeCallCount = 0

    // MARK: - Last Call Parameters

    var lastSuggestRecipeIngredients: [String]?
    var lastSuggestRecipeAge: Int?
    var lastSageQuestion: String?
    var lastSageContext: String?
    var lastNutrientRequested: String?
    var lastCustomFoodName: String?
    var lastAnalyzeRecipeTitle: String?
    var lastAnalyzeRecipeIngredients: String?

    // MARK: - Overridden Methods

    override func identifyFoodFromImage(_ image: UIImage) async throws -> String {
        identifyFoodFromImageCallCount += 1

        if shouldThrowError {
            throw mockError
        }

        return mockIdentifyFoodResult
    }

    override func suggestRecipe(ingredients: [String], ageInMonths: Int) async throws -> Recipe {
        suggestRecipeCallCount += 1
        lastSuggestRecipeIngredients = ingredients
        lastSuggestRecipeAge = ageInMonths

        if shouldThrowError {
            throw mockError
        }

        return mockRecipe
    }

    override func askSageAssistant(question: String, context: String, currentScreenContext: String? = nil) async throws -> String {
        askSageAssistantCallCount += 1
        lastSageQuestion = question
        lastSageContext = context

        if shouldThrowError {
            throw mockError
        }

        return mockSageResponse
    }

    override func predictSleepWindow(recentSleepLogs: [SleepLog], currentTime: Date, lastWakeTime: Date?, ageInMonths: Int) async throws -> SleepPredictionResponse {
        predictSleepWindowCallCount += 1

        if shouldThrowError {
            throw mockError
        }

        return mockSleepPrediction
    }

    override func generatePickyEaterStrategy(enemyFood: String, safeFood: String, ageInMonths: Int, preferredStrategy: String? = nil) async throws -> PickyEaterStrategyResponse {
        generatePickyEaterStrategyCallCount += 1

        if shouldThrowError {
            throw mockError
        }

        return mockPickyEaterStrategy
    }

    override func suggestNutrientRichFoods(nutrient: String, ageInMonths: Int, triedFoodIds: [String]) async throws -> [NutrientFoodSuggestion] {
        suggestNutrientRichFoodsCallCount += 1
        lastNutrientRequested = nutrient

        if shouldThrowError {
            throw mockError
        }

        return mockNutrientSuggestions
    }

    override func generateFlavorPairings(triedFoods: [TriedFoodLog], childName: String) async throws -> FlavorPairingResponse {
        generateFlavorPairingsCallCount += 1

        if shouldThrowError {
            throw mockError
        }

        return mockFlavorPairings
    }

    override func analyzeCustomFood(name: String) async throws -> CustomFoodDetails {
        analyzeCustomFoodCallCount += 1
        lastCustomFoodName = name

        if shouldThrowError {
            throw mockError
        }

        return mockCustomFoodDetails
    }

    override func analyzePackage(image: UIImage) async throws -> CustomFoodDetails {
        analyzePackageCallCount += 1

        if shouldThrowError {
            throw mockError
        }

        return mockCustomFoodDetails
    }

    override func analyzeRecipe(title: String, ingredients: String) async throws -> CustomFoodDetails {
        analyzeRecipeCallCount += 1
        lastAnalyzeRecipeTitle = title
        lastAnalyzeRecipeIngredients = ingredients

        if shouldThrowError {
            throw mockError
        }

        return mockCustomFoodDetails
    }

    // MARK: - Helper Methods

    func reset() {
        shouldThrowError = false
        mockError = GeminiError.invalidResponse

        identifyFoodFromImageCallCount = 0
        suggestRecipeCallCount = 0
        askSageAssistantCallCount = 0
        predictSleepWindowCallCount = 0
        generatePickyEaterStrategyCallCount = 0
        suggestNutrientRichFoodsCallCount = 0
        generateFlavorPairingsCallCount = 0
        analyzeCustomFoodCallCount = 0
        analyzePackageCallCount = 0
        analyzeRecipeCallCount = 0

        lastSuggestRecipeIngredients = nil
        lastSuggestRecipeAge = nil
        lastSageQuestion = nil
        lastSageContext = nil
        lastNutrientRequested = nil
        lastCustomFoodName = nil
        lastAnalyzeRecipeTitle = nil
        lastAnalyzeRecipeIngredients = nil
    }
}
