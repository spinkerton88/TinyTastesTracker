//
//  ToddlerManager.swift
//  TinyTastesTracker
//
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAnalytics
import WidgetKit

@Observable
class ToddlerManager {
    // Data Arrays (Updated via Firestore Listeners)
    // We keep ALL logs for the owner to handle switching, or just filter in listener?
    // Better to filter in listener for the ACTIVE child, to mimic "loading data for this view".
    // But if we switch profiles, we call loadData again?
    // Yes, AppState calls loadData on profile switch usually.
    var foodLogs: [TriedFoodLog] = []
    var mealLogs: [MealLog] = []
    var nutrientGoals: NutrientGoals?

    // Dependencies
    private let notificationManager: NotificationManager

    // Firestore Services
    private let foodService = FirestoreService<TriedFoodLog>(collectionName: "tried_food_logs")
    private let mealService = FirestoreService<MealLog>(collectionName: "meal_logs")
    private let goalService = FirestoreService<NutrientGoals>(collectionName: "nutrient_goals")

    // Listener Registrations
    private var listeners: [ListenerRegistration] = []

    // Dependency - data provider closure
    var getAllKnownFoods: () -> [FoodItem] = { [] }

    // MARK: - Initialization

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    // MARK: - Food Tracking

    var triedFoodsCount: Int {
        // Count unique foods tried (marked as tried)
        Set(foodLogs.filter { $0.isMarkedAsTried }.map { $0.foodId }).count
    }

    func isFoodTried(_ foodId: String) -> Bool {
        // Check if any log exists for this food that is marked as tried
        foodLogs.contains { $0.foodId == foodId && $0.isMarkedAsTried }
    }

    func saveFoodLog(_ log: TriedFoodLog, ownerId: String, childId: String) async throws {
        var logToSave = log
        let isNew = logToSave.id == nil
        
        // 1. Prepare ID and metadata
        if isNew {
            logToSave.id = UUID().uuidString
            // Calculate try count based on current local state
            let existingLogsForFood = foodLogs.filter { $0.foodId == log.foodId && $0.isMarkedAsTried }
            logToSave.tryCount = existingLogsForFood.count + 1
        }
        
        // 2. Optimistic Update (Local)
        if isNew {
            foodLogs.append(logToSave)
        } else {
            if let index = foodLogs.firstIndex(where: { $0.id == logToSave.id }) {
                foodLogs[index] = logToSave
            }
        }
        
        // 3. Network / Queue Logic
        guard NetworkMonitor.shared.isConnected else {
            // Queue for offline sync
            if let encoded = try? JSONEncoder().encode(logToSave) {
                let operation = QueuedOperation(
                    type: .foodLog,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            // Offline success - return without error so UI stays consistent
            return
        }
        
        // 4. Online Save
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                if isNew, let id = logToSave.id {
                    // Use add with specific ID to match our optimistic ID
                    try await self.foodService.add(logToSave, withId: id)
                } else {
                    // Update existing
                    try await self.foodService.update(logToSave)
                }
            }
        }

        // Track analytics event
        if isNew {
            Analytics.logEvent("food_tried", parameters: [
                "food_id": logToSave.foodId,
                "reaction": logToSave.reaction,
                "try_count": logToSave.tryCount
            ])
        }

        updateRainbowProgressWidget()
    }
    
    /// Check if a food contains high-risk allergens and return allergen info
    /// Only triggers for TRUE ALLERGIES (IgE-mediated), not intolerances
    func checkForHighRiskAllergen(foodId: String) -> (foodName: String, allergenName: String)? {
        guard let food = getAllKnownFoods().first(where: { $0.id == foodId }) else {
            return nil
        }
        
        // Only trigger for high-risk allergens
        guard food.allergyRisk == .high, !food.allergens.isEmpty else {
            return nil
        }
        
        // Get the primary allergen (first in list)
        let allergenName = food.allergens.first?.capitalized ?? "Unknown Allergen"
        
        // CRITICAL: Only trigger monitoring for TRUE ALLERGIES, not intolerances
        guard CommonAllergens.isTrueAllergy(allergenName) else {
            return nil
        }
        
        return (foodName: food.name, allergenName: allergenName)
    }

    func unmarkFoodAsTried(_ foodId: String) {
        // Find log for this food
        if let log = foodLogs.filter({ $0.foodId == foodId && $0.isMarkedAsTried }).sorted(by: { $0.date > $1.date }).first {
            var updatedLog = log
            updatedLog.isMarkedAsTried = false
            updatedLog.unmarkedAt = Date()
            
            // Optimistic Update
            if let index = foodLogs.firstIndex(where: { $0.id == updatedLog.id }) {
                foodLogs[index] = updatedLog
            }
            
            Task {
                do {
                    try await foodService.update(updatedLog)
                    updateRainbowProgressWidget()
                } catch {
                    print("Error unmarking food: \(error)")
                    // Revert optimistic update on hard error? 
                    // For now, assume eventual consistency or retry
                }
            }
        }
    }
    
    func undoUnmarkFood(_ foodId: String) {
         if let log = foodLogs.filter({ $0.foodId == foodId && !$0.isMarkedAsTried }).sorted(by: { $0.date > $1.date }).first {
            var updatedLog = log
            updatedLog.isMarkedAsTried = true
            updatedLog.unmarkedAt = nil
             
            // Optimistic Update
            if let index = foodLogs.firstIndex(where: { $0.id == updatedLog.id }) {
                foodLogs[index] = updatedLog
            }
             
            Task {
                do {
                    try await foodService.update(updatedLog)
                    updateRainbowProgressWidget()
                } catch {
                    print("Error undoing unmark food: \(error)")
                }
            }
        }
    }

    func deleteFoodLog(_ log: TriedFoodLog) {
        guard let id = log.id else { return }
        
        // Optimistic Delete
        foodLogs.removeAll { $0.id == id }
        
        Task {
            try? await foodService.delete(id: id)
            updateRainbowProgressWidget()
        }
    }

    // MARK: - Meal Logging

    func saveMealLog(_ log: MealLog, ownerId: String, childId: String) async throws {
        var logToSave = log
        let isNew = logToSave.id == nil
        
        // 1. Prepare ID
        if isNew {
            logToSave.id = UUID().uuidString
        }
        
        // 2. Optimistic Update (Local)
        if let index = mealLogs.firstIndex(where: { $0.id == logToSave.id }) {
             mealLogs[index] = logToSave
        } else {
             mealLogs.append(logToSave)
             // Sort to keep "Today's Logs" ordered correctly immediately
             mealLogs.sort { $0.timestamp > $1.timestamp }
        }
        
        // Update Rainbow Progress Widget Optimistically
        updateRainbowProgressWidget()
        
        // 3. Network / Queue Logic
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(logToSave) {
                let operation = QueuedOperation(
                    type: .mealLog,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            // Offline success
            return
        }
        
        // 4. Online Save
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                if isNew, let id = logToSave.id {
                    try await self.mealService.add(logToSave, withId: id)
                } else {
                    try await self.mealService.update(logToSave)
                }
            }
        }
        
        // Also update tried foods log for each item in the meal
        for foodId in log.foods {
            if !isFoodTried(foodId) {
                // Resolve food name from ID
                let foodName = getAllKnownFoods().first(where: { $0.id == foodId })?.name ?? foodId.replacingOccurrences(of: "_", with: " ").capitalized

                let triedLog = TriedFoodLog(
                    ownerId: ownerId,
                    childId: childId,
                    foodId: foodId,
                    foodName: foodName,
                    date: log.timestamp,
                    reaction: 3, // Neutral default
                    meal: log.mealType
                )
                try await saveFoodLog(triedLog, ownerId: ownerId, childId: childId)
            }
        }
        
        // Schedule meal reminder notification
        Task {
            await scheduleMealReminderIfEnabled(mealType: log.mealType, childName: "Baby") // Needs name
        }
    }

    func deleteMealLog(_ log: MealLog) {
        guard let id = log.id else { return }
        
        // Optimistic Delete
        mealLogs.removeAll { $0.id == id }
        updateRainbowProgressWidget()
        
        Task {
            try? await mealService.delete(id: id)
        }
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
            // Default meal times
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
                return now.addingTimeInterval(3 * 3600)
            }
        }
        
        var nextMealDate = calendar.date(bySettingHour: averageHour, minute: averageMinute, second: 0, of: now) ?? now
        if nextMealDate <= now {
            nextMealDate = calendar.date(byAdding: .day, value: 1, to: nextMealDate) ?? now.addingTimeInterval(24 * 3600)
        }
        return nextMealDate
    }
    
    private func scheduleMealReminderIfEnabled(mealType: MealType, childName: String) async {
        let nextMealTime = calculateNextMealTime(after: mealType)
        let leadTime = UserDefaults.standard.integer(forKey: "feed_notification_lead_time")
        let leadTimeMinutes = leadTime > 0 ? leadTime : 30

        await MainActor.run {
            guard notificationManager.feedNotificationsEnabled else { return }
            guard notificationManager.permissionStatus == .authorized else { return }

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

        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }

        if let showOnlyTried = showOnlyTried {
            if showOnlyTried {
                filtered = filtered.filter { isFoodTried($0.id) }
            } else {
                filtered = filtered.filter { !isFoodTried($0.id) }
            }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { food in
                food.name.localizedCaseInsensitiveContains(searchText) ||
                food.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    func categoryProgress(_ category: FoodCategory) -> (tried: Int, total: Int) {
        let categoryFoods = getAllKnownFoods().filter { $0.category == category }
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
            if let food = getAllKnownFoods().first(where: { $0.id == foodId }) {
                colorCounts[food.color, default: 0] += 1
            }
        }

        return colorCounts
    }

    private func updateRainbowProgressWidget() {
        let colorCounts = rainbowProgress
        let progressData: [ColorProgressData] = FoodColor.allCases.map { color in
            let count = colorCounts[color] ?? 0
            return ColorProgressData(color: color, count: count, goal: 7)
        }
        WidgetDataManager.saveRainbowProgress(progressData, timeRange: "week")
    }

    // MARK: - Nutrition Tracking

    var weeklyNutritionSummary: [Nutrient: Int] {
        let last7Days = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentMeals = mealLogs.filter { $0.timestamp >= last7Days }

        var nutrientCounts: [Nutrient: Int] = [
            .iron: 0, .calcium: 0, .vitaminC: 0, .omega3: 0, .protein: 0
        ]

        let allFoodIds = recentMeals.flatMap { $0.foods }.filter { isFoodTried($0) }
        
        for foodId in allFoodIds {
            if let food = getAllKnownFoods().first(where: { $0.id == foodId }) {
                for nutrient in food.nutrients {
                    nutrientCounts[nutrient, default: 0] += 1
                }
            }
        }

        return nutrientCounts
    }

    func detectNutrientGaps() -> [Nutrient] {
        let summary = weeklyNutritionSummary
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
        ownerId: String,
        childId: String
    ) {
        if var existing = nutrientGoals {
            existing.ironGoal = iron
            existing.calciumGoal = calcium
            existing.vitaminCGoal = vitaminC
            existing.omega3Goal = omega3
            existing.proteinGoal = protein
            // existing.lastModified = Date() // If property exists

            Task {
                do {
                    try await goalService.update(existing)
                    // Also update local copy immediately? Listener will do it.
                } catch {
                    print("Error updating nutrient goals: \(error)")
                }
            }
        } else {
            let newGoals = NutrientGoals(
                ownerId: ownerId,
                childId: childId,
                ironGoal: iron,
                calciumGoal: calcium,
                vitaminCGoal: vitaminC,
                omega3Goal: omega3,
                proteinGoal: protein
            )

            Task {
                do {
                    try await goalService.add(newGoals)
                } catch {
                    print("Error adding nutrient goals: \(error)")
                }
            }
        }
    }

    // MARK: - Chart Data

    func getCategoryDistribution() -> [CategoryDistribution] {
        let triedFoodIds = Set(foodLogs.filter { $0.isMarkedAsTried }.map { $0.foodId })
        var categoryCounts: [FoodCategory: (count: Int, color: FoodColor)] = [:]
        let categorizedFoods = getAllKnownFoods().filter { triedFoodIds.contains($0.id) }

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

    func loadData(ownerId: String, childId: String) {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        // Listen for Food Logs
        listeners.append(foodService.addListener(forUserId: ownerId) { [weak self] logs in
            // Filter by childId
            self?.foodLogs = logs.filter { $0.childId == childId }
        })

        // Listen for Meal Logs
        listeners.append(mealService.addListener(forUserId: ownerId) { [weak self] logs in
            // Filter by childId and sort
            self?.mealLogs = logs.filter { $0.childId == childId }.sorted { $0.timestamp > $1.timestamp }
        })

        // Listen for Nutrient Goals
        listeners.append(goalService.addListener(forUserId: ownerId) { [weak self] goals in
            // Should be only one per child?
             self?.nutrientGoals = goals.first { $0.childId == childId }
        })
    }
}
