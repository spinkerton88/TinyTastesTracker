//
//  ProfileManager.swift
//  TinyTastesTracker
//
//  Manages multiple child profiles with profile switching and comparison features
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class ProfileManager {

    // MARK: - Properties

    /// All child profiles stored in the app
    private(set) var profiles: [UserProfile] = []

    /// The currently active profile
    private(set) var activeProfileId: UUID?

    /// The active profile (computed from activeProfileId)
    var activeProfile: UserProfile? {
        guard let activeProfileId = activeProfileId else { return nil }
        return profiles.first { $0.id == activeProfileId }
    }

    // MARK: - Persistence Key
    private let activeProfileKey = "ProfileManager.activeProfileId"

    // MARK: - Initialization

    init() {
        // Load active profile ID from UserDefaults
        if let savedId = UserDefaults.standard.string(forKey: activeProfileKey),
           let uuid = UUID(uuidString: savedId) {
            self.activeProfileId = uuid
        }
    }

    // MARK: - Profile Management

    /// Load all profiles from SwiftData
    func loadProfiles(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.babyName)]
        )

        do {
            profiles = try context.fetch(descriptor)

            // If no active profile is set, use the first one
            if activeProfileId == nil, let firstProfile = profiles.first {
                setActiveProfile(firstProfile)
            }

            // Validate active profile still exists
            if let activeId = activeProfileId,
               !profiles.contains(where: { $0.id == activeId }) {
                // Active profile was deleted, switch to first available
                activeProfileId = profiles.first?.id
                saveActiveProfileId()
            }
        } catch {
            print("⚠️ Failed to load profiles: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }

    /// Create a new child profile
    func createProfile(
        name: String,
        birthDate: Date,
        gender: Gender,
        allergies: [String]? = nil,
        context: ModelContext
    ) {
        let newProfile = UserProfile(
            babyName: name,
            birthDate: birthDate,
            gender: gender,
            knownAllergies: allergies
        )

        context.insert(newProfile)

        do {
            try context.save()
            profiles.append(newProfile)

            // If this is the first profile, make it active
            if profiles.count == 1 {
                setActiveProfile(newProfile)
            }
        } catch {
            print("⚠️ Failed to save profile: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }

    /// Update an existing profile
    func updateProfile(
        _ profile: UserProfile,
        name: String? = nil,
        birthDate: Date? = nil,
        gender: Gender? = nil,
        allergies: [String]? = nil,
        preferredMode: AppMode? = nil,
        context: ModelContext
    ) {
        if let name = name {
            profile.babyName = name
        }
        if let birthDate = birthDate {
            profile.birthDate = birthDate
        }
        if let gender = gender {
            profile.gender = gender
        }
        if let allergies = allergies {
            profile.knownAllergies = allergies
        }
        if let mode = preferredMode {
            profile.preferredMode = mode
        }

        do {
            try context.save()
        } catch {
            print("⚠️ Failed to update profile: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }

    /// Delete a profile
    func deleteProfile(_ profile: UserProfile, context: ModelContext) {
        // Don't allow deleting the last profile
        guard profiles.count > 1 else {
            print("⚠️ Cannot delete the last profile")
            return
        }

        let wasActive = profile.id == activeProfileId

        context.delete(profile)

        do {
            try context.save()
            profiles.removeAll { $0.id == profile.id }

            // If deleted profile was active, switch to first available
            if wasActive, let firstProfile = profiles.first {
                setActiveProfile(firstProfile)
            }
        } catch {
            print("⚠️ Failed to delete profile: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }

    /// Switch to a different active profile
    func setActiveProfile(_ profile: UserProfile) {
        activeProfileId = profile.id
        saveActiveProfileId()

        // Post notification for app-wide profile change
        NotificationCenter.default.post(name: .activeProfileChanged, object: profile)
    }

    /// Switch to active profile by ID
    func setActiveProfile(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else {
            print("⚠️ Profile not found: \(id)")
            return
        }
        setActiveProfile(profile)
    }

    // MARK: - Sibling Comparison

    /// Get growth data for all profiles for comparison
    /// Note: Currently fetches ALL growth data since logs don't have profileId
    /// In a multi-profile scenario, this would need profile-specific filtering
    func getGrowthComparison(for metric: GrowthMetric, context: ModelContext) -> [ProfileGrowthData] {
        // Fetch all growth measurements
        let descriptor = FetchDescriptor<GrowthMeasurement>(
            sortBy: [SortDescriptor(\.date)]
        )
        
        guard let measurements = try? context.fetch(descriptor) else {
            return profiles.map { ProfileGrowthData(profile: $0, metric: metric, dataPoints: []) }
        }
        
        // For single-profile apps, all data belongs to active profile
        // For multi-profile, this would need profileId filtering
        return profiles.map { profile in
            let dataPoints: [(date: Date, value: Double)] = measurements.compactMap { measurement in
                let value: Double?
                switch metric {
                case .weight:
                    value = measurement.weight
                case .height:
                    value = measurement.height
                case .headCircumference:
                    value = measurement.headCircumference
                }
                
                guard let unwrappedValue = value else { return nil }
                return (date: measurement.date, value: unwrappedValue)
            }
            
            return ProfileGrowthData(
                profile: profile,
                metric: metric,
                dataPoints: dataPoints
            )
        }
    }

    /// Get nutrition summaries for all profiles
    /// Note: Currently fetches ALL meal data since logs don't have profileId
    /// In a multi-profile scenario, this would need profile-specific filtering
    func getNutritionComparison(context: ModelContext, allKnownFoods: [FoodItem]) -> [ProfileNutritionData] {
        // Fetch recent meal logs (last 7 days)
        let last7Days = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let mealDescriptor = FetchDescriptor<MealLog>(
            predicate: #Predicate { $0.timestamp >= last7Days }
        )
        
        guard let meals = try? context.fetch(mealDescriptor) else {
            return profiles.map { ProfileNutritionData(profile: $0, rainbowProgress: [:], nutrientCounts: [:]) }
        }
        
        // Calculate rainbow progress and nutrient counts
        var rainbowProgress: [FoodColor: Int] = [:]
        var nutrientCounts: [Nutrient: Int] = [:]
        
        let allFoodIds = meals.flatMap { $0.foods }
        for foodId in allFoodIds {
            if let food = allKnownFoods.first(where: { $0.id == foodId }) {
                // Count colors
                rainbowProgress[food.color, default: 0] += 1
                
                // Count nutrients
                for nutrient in food.nutrients {
                    nutrientCounts[nutrient, default: 0] += 1
                }
            }
        }
        
        // For single-profile apps, all data belongs to active profile
        // For multi-profile, this would need profileId filtering
        return profiles.map { profile in
            ProfileNutritionData(
                profile: profile,
                rainbowProgress: rainbowProgress,
                nutrientCounts: nutrientCounts
            )
        }
    }
    
    /// Get meal count for a specific profile
    /// Note: Currently returns total count since logs don't have profileId
    /// In a multi-profile scenario, this would filter by profileId
    func getMealCount(for profileId: UUID, context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<MealLog>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Private Helpers

    private func saveActiveProfileId() {
        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId.uuidString, forKey: activeProfileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
        }
    }
}

// MARK: - Supporting Types

enum GrowthMetric {
    case weight
    case height
    case headCircumference
}

struct ProfileGrowthData {
    let profile: UserProfile
    let metric: GrowthMetric
    let dataPoints: [(date: Date, value: Double)]
}

struct ProfileNutritionData: Identifiable {
    var id: UUID { profile.id }
    let profile: UserProfile
    let rainbowProgress: [FoodColor: Int]
    let nutrientCounts: [Nutrient: Int]
}

// MARK: - Notification Names

extension Notification.Name {
    static let activeProfileChanged = Notification.Name("activeProfileChanged")
}
