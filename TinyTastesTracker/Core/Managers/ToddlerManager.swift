//
//  ToddlerManager.swift
//  TinyTastesTracker
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class ToddlerManager {
    var foodLogs: [TriedFoodLog] = []
    var mealLogs: [MealLog] = []
    var nutrientGoals: NutrientGoals?

    // Dependency - needs to be injected or passed
    private(set) var allKnownFoods: [FoodItem] = []

    // MARK: - Initialization

    func updateKnownFoods(_ foods: [FoodItem]) {
        self.allKnownFoods = foods
    }

    // MARK: - Food Tracking

    var triedFoodsCount: Int {
        Set(foodLogs.filter { $0.isMarkedAsTried }.map { $0.id }).count
    }

    func isFoodTried(_ foodId: String) -> Bool {
        foodLogs.contains { $0.id == foodId && $0.isMarkedAsTried }
    }

    func saveFoodLog(_ log: TriedFoodLog, context: ModelContext) {
        if let existingIndex = foodLogs.firstIndex(where: { $0.id == log.id }) {
            foodLogs[existingIndex] = log
        } else {
            foodLogs.append(log)
            context.insert(log)
        }

        // Update Rainbow Progress Widget
        updateRainbowProgressWidget()
    }
    
    /// Check if a food contains high-risk allergens and return allergen info
    /// Only triggers for TRUE ALLERGIES (IgE-mediated), not intolerances
    /// - Parameter foodId: The food ID to check
    /// - Returns: Tuple with allergen info if high-risk true allergy, nil otherwise
    func checkForHighRiskAllergen(foodId: String) -> (foodName: String, allergenName: String)? {
        guard let food = allKnownFoods.first(where: { $0.id == foodId }) else {
            return nil
        }
        
        // Only trigger for high-risk allergens
        guard food.allergyRisk == .high, !food.allergens.isEmpty else {
            return nil
        }
        
        // Get the primary allergen (first in list)
        let allergenName = food.allergens.first?.capitalized ?? "Unknown Allergen"
        
        // CRITICAL: Only trigger monitoring for TRUE ALLERGIES, not intolerances
        // Intolerances are tracked but don't need urgent monitoring prompts
        guard CommonAllergens.isTrueAllergy(allergenName) else {
            return nil
        }
        
        return (foodName: food.name, allergenName: allergenName)
    }

    func unmarkFoodAsTried(_ foodId: String, context: ModelContext) {
        if let log = foodLogs.first(where: { $0.id == foodId }) {
            log.isMarkedAsTried = false
            log.unmarkedAt = Date()
            
            // Try to save changes immediately
            try? context.save()
            updateRainbowProgressWidget()
        }
    }
    
    func undoUnmarkFood(_ foodId: String, context: ModelContext) {
         if let log = foodLogs.first(where: { $0.id == foodId }) {
            log.isMarkedAsTried = true
            log.unmarkedAt = nil
             
            // Try to save changes immediately
            try? context.save()
            updateRainbowProgressWidget()
        }
    }

    func deleteFoodLog(_ log: TriedFoodLog, context: ModelContext) {
        if let index = foodLogs.firstIndex(where: { $0.id == log.id }) {
            foodLogs.remove(at: index)
        }
        context.delete(log)
        updateRainbowProgressWidget()
    }

    // MARK: - Meal Logging

    func saveMealLog(_ log: MealLog, context: ModelContext, userProfile: UserProfile? = nil) {
        mealLogs.append(log)
        context.insert(log)

        // Also update tried foods log for each item in the meal
        for foodId in log.foods {
            if !isFoodTried(foodId) {
                let triedLog = TriedFoodLog(
                    id: foodId,
                    date: log.timestamp,
                    reaction: 3, // Neutral default
                    meal: log.mealType
                )
                saveFoodLog(triedLog, context: context)
            }
        }

        // Update Rainbow Progress Widget
        updateRainbowProgressWidget()
        
        // Schedule meal reminder notification
        if let profile = userProfile {
            Task {
                await scheduleMealReminderIfEnabled(mealType: log.mealType, childName: profile.babyName)
            }
        }
    }

    func deleteMealLog(_ log: MealLog, context: ModelContext) {
        if let index = mealLogs.firstIndex(where: { $0.id == log.id }) {
            mealLogs.remove(at: index)
        }
        context.delete(log)
        updateRainbowProgressWidget()
    }
    
    // MARK: - Meal Reminder Notifications
    
    /// Calculate the next expected meal time based on meal type and patterns
    private func calculateNextMealTime(after mealType: MealType) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get meals from last 7 days to establish pattern
        let last7Days = now.addingTimeInterval(-7 * 24 * 3600)
        let recentMeals = mealLogs.filter { $0.timestamp >= last7Days && $0.mealType == mealType }
        
        // Calculate average time of day for this meal type
        var averageHour: Int
        var averageMinute: Int
        
        if !recentMeals.isEmpty {
            let totalMinutes = recentMeals.reduce(0) { total, meal in
                let components = calendar.dateComponents([.hour, .minute], from: meal.timestamp)
                return total + (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
            let avgMinutes = totalMinutes / recentMeals.count
            averageHour = avgMinutes / 60
            averageMinute = avgMinutes % 60
        } else {
            // Default meal times if no pattern exists
            switch mealType {
            case .breakfast:
                averageHour = 7
                averageMinute = 30
            case .lunch:
                averageHour = 12
                averageMinute = 0
            case .dinner:
                averageHour = 18
                averageMinute = 0
            case .snack:
                // For snacks, use 3 hours from now
                return now.addingTimeInterval(3 * 3600)
            }
        }
        
        // Determine next occurrence of this meal
        var nextMealDate = calendar.date(bySettingHour: averageHour, minute: averageMinute, second: 0, of: now) ?? now
        
        // If the calculated time is in the past today, schedule for tomorrow
        if nextMealDate <= now {
            nextMealDate = calendar.date(byAdding: .day, value: 1, to: nextMealDate) ?? now.addingTimeInterval(24 * 3600)
        }
        
        return nextMealDate
    }
    
    /// Schedule a meal reminder notification if enabled
    private func scheduleMealReminderIfEnabled(mealType: MealType, childName: String) async {
        // Calculate next meal time
        let nextMealTime = calculateNextMealTime(after: mealType)
        
        // Get lead time from settings
        let leadTime = UserDefaults.standard.integer(forKey: "feed_notification_lead_time")
        let leadTimeMinutes = leadTime > 0 ? leadTime : 30 // Default to 30 minutes
        
        // Schedule the notification on main actor
        await MainActor.run {
            let notificationManager = NotificationManager.shared
            
            // Check if feed notifications are enabled
            guard notificationManager.feedNotificationsEnabled else {
                return
            }
            
            // Check if permissions are granted
            guard notificationManager.permissionStatus == .authorized else {
                return
            }
            
            // Schedule the notification
            Task {
                do {
                    try await notificationManager.scheduleFeedReminder(
                        nextFeedTime: nextMealTime,
                        leadTimeMinutes: leadTimeMinutes,
                        childName: childName
                    )
                } catch {
                    print("Error scheduling meal reminder: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Food Filtering

    func filteredFoods(searchText: String, category: FoodCategory?, showOnlyTried: Bool?, from foods: [FoodItem]) -> [FoodItem] {
        var filtered = foods

        // Apply category filter
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }

        // Apply tried/untried filter
        if let showOnlyTried = showOnlyTried {
            if showOnlyTried {
                filtered = filtered.filter { isFoodTried($0.id) }
            } else {
                filtered = filtered.filter { !isFoodTried($0.id) }
            }
        }

        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { food in
                food.name.localizedCaseInsensitiveContains(searchText) ||
                food.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    func categoryProgress(_ category: FoodCategory) -> (tried: Int, total: Int) {
        let categoryFoods = allKnownFoods.filter { $0.category == category }
        // isFoodTried now respects isMarkedAsTried
        let triedCount = categoryFoods.filter { isFoodTried($0.id) }.count
        return (tried: triedCount, total: categoryFoods.count)
    }

    // MARK: - Rainbow Progress (Eat the Rainbow)

    var rainbowProgress: [FoodColor: Int] {
        let last7Days = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentMeals = mealLogs.filter { $0.timestamp >= last7Days }

        var colorCounts: [FoodColor: Int] = [:]

        // Only count foods that are currently marked as tried
        let allFoodIds = recentMeals.flatMap { $0.foods }.filter { isFoodTried($0) }
        
        for foodId in allFoodIds {
            if let food = allKnownFoods.first(where: { $0.id == foodId }) {
                colorCounts[food.color, default: 0] += 1
            }
        }

        return colorCounts
    }

    private func updateRainbowProgressWidget() {
        // Calculate progress for each color
        let colorCounts = rainbowProgress
        let progressData: [ColorProgressData] = FoodColor.allCases.map { color in
            let count = colorCounts[color] ?? 0
            return ColorProgressData(color: color, count: count, goal: 7)
        }

        // Save to WidgetDataManager for widget display
        WidgetDataManager.saveRainbowProgress(progressData, timeRange: "week")
    }

    // MARK: - Nutrition Tracking

    var weeklyNutritionSummary: [Nutrient: Int] {
        let last7Days = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentMeals = mealLogs.filter { $0.timestamp >= last7Days }

        var nutrientCounts: [Nutrient: Int] = [
            .iron: 0, .calcium: 0, .vitaminC: 0, .omega3: 0, .protein: 0
        ]

        // Only count foods that are currently marked as tried
        let allFoodIds = recentMeals.flatMap { $0.foods }.filter { isFoodTried($0) }
        
        for foodId in allFoodIds {
            if let food = allKnownFoods.first(where: { $0.id == foodId }) {
                for nutrient in food.nutrients {
                    nutrientCounts[nutrient, default: 0] += 1
                }
            }
        }

        return nutrientCounts
    }

    func detectNutrientGaps() -> [Nutrient] {
        let summary = weeklyNutritionSummary
        // Arbitrary weekly targets: Iron=5, Calcium=7, VitC=7, Omega3=3, Protein=14
        var gaps: [Nutrient] = []

        if (summary[.iron] ?? 0) < 5 { gaps.append(.iron) }
        if (summary[.calcium] ?? 0) < 7 { gaps.append(.calcium) }
        if (summary[.vitaminC] ?? 0) < 7 { gaps.append(.vitaminC) }
        if (summary[.omega3] ?? 0) < 3 { gaps.append(.omega3) }
        if (summary[.protein] ?? 0) < 14 { gaps.append(.protein) }

        return gaps
    }

    // MARK: - Nutrient Goals Management

    func updateNutrientGoals(
        iron: Int,
        calcium: Int,
        vitaminC: Int,
        omega3: Int,
        protein: Int,
        userId: UUID,
        context: ModelContext
    ) {
        if let existing = nutrientGoals {
            existing.ironGoal = iron
            existing.calciumGoal = calcium
            existing.vitaminCGoal = vitaminC
            existing.omega3Goal = omega3
            existing.proteinGoal = protein
            existing.lastModified = Date()
        } else {
            let newGoals = NutrientGoals(
                userId: userId,
                ironGoal: iron,
                calciumGoal: calcium,
                vitaminCGoal: vitaminC,
                omega3Goal: omega3,
                proteinGoal: protein
            )
            nutrientGoals = newGoals
            context.insert(newGoals)
        }
    }

    // MARK: - Chart Data

    func getCategoryDistribution() -> [CategoryDistribution] {
        // Get tried food IDs (only marked ones)
        let triedFoodIds = Set(foodLogs.filter { $0.isMarkedAsTried }.map { $0.id })

        // Count by category
        var categoryCounts: [FoodCategory: (count: Int, color: FoodColor)] = [:]
        let categorizedFoods = allKnownFoods.filter { triedFoodIds.contains($0.id) }

        for food in categorizedFoods {
            if categoryCounts[food.category] == nil {
                categoryCounts[food.category] = (1, food.color)
            } else {
                categoryCounts[food.category]?.count += 1
            }
        }

        let totalCount = triedFoodIds.count
        guard totalCount > 0 else { return [] }

        return categoryCounts.map { category, data in
            CategoryDistribution(
                id: category.rawValue,
                category: category.rawValue.capitalized,
                count: data.count,
                percentage: Double(data.count) / Double(totalCount) * 100.0,
                color: data.color
            )
        }
    }

    func getNutrientProgress() -> [NutrientProgress] {
        let summary = weeklyNutritionSummary

        // Use custom goals if available, otherwise defaults
        let goals: [Nutrient: Int]
        if let customGoals = nutrientGoals {
            goals = [
                .iron: customGoals.ironGoal,
                .calcium: customGoals.calciumGoal,
                .vitaminC: customGoals.vitaminCGoal,
                .omega3: customGoals.omega3Goal,
                .protein: customGoals.proteinGoal
            ]
        } else {
            goals = NutrientGoals.defaultGoals
        }

        return goals.map { nutrient, goal in
            NutrientProgress(
                id: nutrient,
                name: nutrient.rawValue.capitalized,
                count: summary[nutrient] ?? 0,
                weeklyGoal: goal
            )
        }.sorted { $0.name < $1.name }
    }

    func getColorProgress() -> [ColorProgress] {
        let progress = rainbowProgress
        let weeklyGoal = 7

        return FoodColor.allCases.map { color in
            ColorProgress(
                id: color,
                color: color,
                count: progress[color] ?? 0,
                goal: weeklyGoal
            )
        }
    }

    // MARK: - Data Loading

    func loadData(context: ModelContext, userId: UUID?) {
        do {
            // Performance optimization: Load only last 30 days of data initially
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            let foodDescriptor = FetchDescriptor<TriedFoodLog>(
                predicate: #Predicate { $0.date >= cutoffDate }
            )
            foodLogs = try context.fetch(foodDescriptor)

            let mealDescriptor = FetchDescriptor<MealLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            mealLogs = try context.fetch(mealDescriptor)

            // Load nutrient goals (not date-dependent)
            if let userId = userId {
                let goalsDescriptor = FetchDescriptor<NutrientGoals>(
                    predicate: #Predicate<NutrientGoals> { $0.userId == userId }
                )
                nutrientGoals = try context.fetch(goalsDescriptor).first
            }
        } catch {
            print("Error loading toddler data: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
    
    /// Load historical data beyond the initial 30-day window
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - beforeDate: Load data before this date
    func loadHistoricalData(context: ModelContext, beforeDate: Date) {
        do {
            // Load older food logs
            let foodDescriptor = FetchDescriptor<TriedFoodLog>(
                predicate: #Predicate { $0.date < beforeDate }
            )
            let olderFood = try context.fetch(foodDescriptor)
            foodLogs.append(contentsOf: olderFood)
            
            // Load older meal logs
            let mealDescriptor = FetchDescriptor<MealLog>(
                predicate: #Predicate { $0.timestamp < beforeDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let olderMeals = try context.fetch(mealDescriptor)
            mealLogs.append(contentsOf: olderMeals)
        } catch {
            print("Error loading historical toddler data: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
}
