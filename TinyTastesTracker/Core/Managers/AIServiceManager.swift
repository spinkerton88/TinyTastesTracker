//
//  AIServiceManager.swift
//  TinyTastesTracker
//

import Foundation
import SwiftUI

@Observable
class AIServiceManager {
    let geminiService = GeminiService()
    let openFoodFactsService = OpenFoodFactsService()

    // MARK: - Custom Food Analysis

    func analyzeCustomFood(name: String) async throws -> CustomFoodDetails {
        try await geminiService.analyzeCustomFood(name: name)
    }

    func analyzePackage(image: UIImage) async throws -> CustomFoodDetails {
        try await geminiService.analyzePackage(image: image)
    }

    func analyzeRecipe(title: String, ingredients: String) async throws -> CustomFoodDetails {
        try await geminiService.analyzeRecipe(title: title, ingredients: ingredients)
    }

    // MARK: - Barcode Lookup

    func lookupBarcode(_ code: String) async throws -> ProductInfo {
        try await openFoodFactsService.lookupBarcode(code)
    }

    // MARK: - Food Identification

    func identifyFood(from image: UIImage) async throws -> String {
        try await geminiService.identifyFoodFromImage(image)
    }

    // MARK: - Recipe Generation

    @MainActor
    func generateRecipe(ingredients: [String], ageInMonths: Int) async throws -> Recipe {
        try await geminiService.suggestRecipe(ingredients: ingredients, ageInMonths: ageInMonths)
    }

    // MARK: - Sage Assistant

    func askSage(
        question: String,
        babyName: String,
        ageInMonths: Int,
        foodLogs: [TriedFoodLog],
        allKnownFoods: [FoodItem]
    ) async throws -> String {
        // Build Context
        var context = "Baby: \(babyName), Age: \(ageInMonths) months.\n"

        // 1. Add Significant Reactions (Priority)
        let problematicLogs = foodLogs.filter { $0.reaction < 4 || !$0.reactionSigns.isEmpty }
            .sorted(by: { $0.date > $1.date })

        if !problematicLogs.isEmpty {
            context += "\n⚠️ KNOWN REACTIONS/ISSUES:\n"
            for log in problematicLogs.prefix(5) {
                let foodName = allKnownFoods.first(where: { $0.id == log.id })?.name ?? log.id
                let signs = log.reactionSigns.isEmpty ? "Disliked (Rating: \(log.reaction)/7)" : log.reactionSigns.joined(separator: ", ")
                let dateStr = log.date.formatted(date: .abbreviated, time: .omitted)
                context += "- \(foodName) (\(dateStr)): \(signs)\n"
            }
        }

        // 2. Add Recently Tried Foods
        let recentLogs = foodLogs.sorted(by: { $0.date > $1.date }).prefix(10)
        if !recentLogs.isEmpty {
            context += "\nRECENTLY EATEN:\n"
            let recentNames = recentLogs.compactMap { log in
                allKnownFoods.first(where: { $0.id == log.id })?.name
            }
            context += recentNames.joined(separator: ", ") // Just a simple list for context
        }

        return try await geminiService.askSageAssistant(question: question, context: context)
    }

    // MARK: - Sleep Prediction

    func predictNextSleepWindow(
        sleepLogs: [SleepLog],
        ageInMonths: Int
    ) async throws -> SleepPredictionResponse {
        let last48Hours = Date().addingTimeInterval(-48 * 3600)
        let recentSleepLogs = sleepLogs.filter { $0.startTime >= last48Hours }
        let lastWakeTime = sleepLogs.first?.endTime

        return try await geminiService.predictSleepWindow(
            recentSleepLogs: recentSleepLogs,
            currentTime: Date(),
            lastWakeTime: lastWakeTime,
            ageInMonths: ageInMonths
        )
    }

    // MARK: - Picky Eater Strategies

    func generatePickyEaterStrategy(
        enemyFoodId: String,
        safeFoodId: String,
        preferredStrategy: String?,
        ageInMonths: Int,
        allKnownFoods: [FoodItem]
    ) async throws -> PickyEaterStrategyResponse {
        let enemyFood = allKnownFoods.first(where: { $0.id == enemyFoodId })?.name ?? enemyFoodId
        let safeFood = allKnownFoods.first(where: { $0.id == safeFoodId })?.name ?? safeFoodId

        return try await geminiService.generatePickyEaterStrategy(
            enemyFood: enemyFood,
            safeFood: safeFood,
            ageInMonths: ageInMonths,
            preferredStrategy: preferredStrategy
        )
    }

    // MARK: - Nutrient Suggestions

    func suggestFoodsForNutrient(
        _ nutrient: Nutrient,
        ageInMonths: Int,
        triedFoodIds: [String]
    ) async throws -> [NutrientFoodSuggestion] {
        return try await geminiService.suggestNutrientRichFoods(
            nutrient: nutrient.rawValue,
            ageInMonths: ageInMonths,
            triedFoodIds: triedFoodIds
        )
    }

    // MARK: - Flavor Pairings

    func generateFlavorPairings(
        triedFoods: [TriedFoodLog],
        childName: String
    ) async throws -> FlavorPairingResponse {
        try await geminiService.generateFlavorPairings(triedFoods: triedFoods, childName: childName)
    }
}
