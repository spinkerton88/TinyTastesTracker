//
//  DataDeletionService.swift
//  TinyTastesTracker
//
//  Created by Antigravity on 1/12/26.
//

import Foundation
import SwiftData

/// Service for managing data deletion operations
/// Provides granular and complete data deletion capabilities for GDPR compliance
@MainActor
class DataDeletionService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Granular Deletion
    
    /// Deletes all meal logs and tried food logs
    func deleteMealLogs() async throws {
        // Delete MealLog entries
        let mealLogDescriptor = FetchDescriptor<MealLog>()
        let mealLogs = try modelContext.fetch(mealLogDescriptor)
        for log in mealLogs {
            modelContext.delete(log)
        }
        
        // Delete TriedFoodLog entries (Foods tab in Explorer mode)
        let triedFoodDescriptor = FetchDescriptor<TriedFoodLog>()
        let triedFoodLogs = try modelContext.fetch(triedFoodDescriptor)
        for log in triedFoodLogs {
            modelContext.delete(log)
        }
        
        try modelContext.save()
    }
    
    /// Deletes all sleep logs
    func deleteSleepLogs() async throws {
        let descriptor = FetchDescriptor<SleepLog>()
        let logs = try modelContext.fetch(descriptor)
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }
    
    /// Deletes all diaper logs
    func deleteDiaperLogs() async throws {
        let descriptor = FetchDescriptor<DiaperLog>()
        let logs = try modelContext.fetch(descriptor)
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }
    
    /// Deletes all bottle logs
    func deleteBottleLogs() async throws {
        let descriptor = FetchDescriptor<BottleFeedLog>()
        let logs = try modelContext.fetch(descriptor)
        for log in logs {
            modelContext.delete(log)
        }
        try modelContext.save()
    }
    
    /// Deletes all growth entries
    func deleteGrowthData() async throws {
        let descriptor = FetchDescriptor<GrowthMeasurement>()
        let entries = try modelContext.fetch(descriptor)
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }
    
    /// Deletes all recipes
    func deleteRecipes() async throws {
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        for recipe in recipes {
            modelContext.delete(recipe)
        }
        try modelContext.save()
    }
    
    /// Deletes all meal plans
    func deleteMealPlans() async throws {
        let descriptor = FetchDescriptor<MealPlanEntry>()
        let plans = try modelContext.fetch(descriptor)
        for plan in plans {
            modelContext.delete(plan)
        }
        try modelContext.save()
    }
    
    /// Deletes all milestones
    func deleteMilestones() async throws {
        let descriptor = FetchDescriptor<Milestone>()
        let milestones = try modelContext.fetch(descriptor)
        for milestone in milestones {
            modelContext.delete(milestone)
        }
        try modelContext.save()
    }
    
    /// Deletes all badges
    func deleteBadges() async throws {
        let descriptor = FetchDescriptor<Badge>()
        let badges = try modelContext.fetch(descriptor)
        for badge in badges {
            modelContext.delete(badge)
        }
        try modelContext.save()
    }
    
    /// Deletes all user profiles
    /// Warning: This will delete all child profiles and their associated data
    func deleteUserProfiles() async throws {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)
        for profile in profiles {
            modelContext.delete(profile)
        }
        try modelContext.save()
    }
    
    // MARK: - Complete Deletion
    
    /// Deletes ALL data from the app
    /// This is a nuclear option and cannot be undone
    /// Use for GDPR "right to erasure" requests
    func deleteAllData() async throws {
        try await deleteMealLogs()  // Now includes TriedFoodLog
        try await deleteSleepLogs()
        try await deleteDiaperLogs()
        try await deleteBottleLogs()
        try await deleteGrowthData()
        try await deleteRecipes()
        try await deleteMealPlans()
        try await deleteMilestones()
        try await deleteBadges()
        
        // Delete custom foods
        let customFoodDescriptor = FetchDescriptor<CustomFood>()
        let customFoods = try modelContext.fetch(customFoodDescriptor)
        for food in customFoods {
            modelContext.delete(food)
        }
        
        // Delete shopping list items
        let shoppingDescriptor = FetchDescriptor<ShoppingListItem>()
        let shoppingItems = try modelContext.fetch(shoppingDescriptor)
        for item in shoppingItems {
            modelContext.delete(item)
        }
        
        // Delete nursing logs
        let nursingDescriptor = FetchDescriptor<NursingLog>()
        let nursingLogs = try modelContext.fetch(nursingDescriptor)
        for log in nursingLogs {
            modelContext.delete(log)
        }
        
        // Delete pumping logs
        let pumpingDescriptor = FetchDescriptor<PumpingLog>()
        let pumpingLogs = try modelContext.fetch(pumpingDescriptor)
        for log in pumpingLogs {
            modelContext.delete(log)
        }
        
        // Delete medication logs
        let medicationDescriptor = FetchDescriptor<MedicationLog>()
        let medicationLogs = try modelContext.fetch(medicationDescriptor)
        for log in medicationLogs {
            modelContext.delete(log)
        }
        
        // Delete user profiles last
        try await deleteUserProfiles()
        
        // Clear UserDefaults
        clearUserDefaults()
        
        try modelContext.save()
    }
    
    // MARK: - Helper Methods
    
    /// Clears app-specific UserDefaults
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "activeProfileID")
        defaults.removeObject(forKey: "isNightMode")
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        // Add other UserDefaults keys as needed
    }
    
    /// Gets count of items for a specific data type
    func getCount<T: PersistentModel>(for type: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Deletion Result

/// Result of a deletion operation
struct DeletionResult {
    let dataType: String
    let itemsDeleted: Int
    let success: Bool
    let error: Error?
}
