//
//  ProfileManager.swift
//  TinyTastesTracker
//
//  Manages multiple child profiles via Firestore
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class ProfileManager {

    // MARK: - Properties

    /// All child profiles stored in the app
    private(set) var profiles: [ChildProfile] = []

    /// The currently active profile ID
    private(set) var activeProfileId: String?

    /// The active profile (computed from activeProfileId)
    var activeProfile: ChildProfile? {
        guard let activeProfileId = activeProfileId else { return nil }
        return profiles.first { $0.id == activeProfileId }
    }

    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let profileService = FirestoreService<ChildProfile>(collectionName: "child_profiles")
    private var ownedProfilesListener: ListenerRegistration?
    private var sharedProfilesListener: ListenerRegistration?

    // Cached profile arrays for merging
    private var ownedProfiles: [ChildProfile] = []
    private var sharedProfiles: [ChildProfile] = []
    
    // MARK: - Persistence Key
    private let activeProfileKey = "ProfileManager.activeProfileId"

    // MARK: - Initialization

    init() {
        // Load active profile ID from UserDefaults
        if let savedId = UserDefaults.standard.string(forKey: activeProfileKey) {
            self.activeProfileId = savedId
        }
    }

    deinit {
        ownedProfilesListener?.remove()
        sharedProfilesListener?.remove()
    }

    // MARK: - Profile Management

    /// Load all profiles for a specific parent (owned + shared)
    func loadProfiles(userId: String) {
        // Remove existing listeners if any
        ownedProfilesListener?.remove()
        sharedProfilesListener?.remove()

        // Listen for profiles owned by this user
        ownedProfilesListener = db.collection("child_profiles")
            .whereField("ownerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("⚠️ Error loading owned profiles: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.ownedProfiles = documents.compactMap { try? $0.data(as: ChildProfile.self) }
                self.mergeProfiles()
            }

        // Listen for profiles shared with this user
        sharedProfilesListener = db.collection("child_profiles")
            .whereField("sharedWith", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("⚠️ Error loading shared profiles: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.sharedProfiles = documents.compactMap { try? $0.data(as: ChildProfile.self) }
                self.mergeProfiles()
            }
    }

    /// Merge owned and shared profiles into single array
    private func mergeProfiles() {
        var allProfiles = [ChildProfile]()

        // Add owned profiles
        allProfiles.append(contentsOf: ownedProfiles)

        // Add shared profiles (deduplicate in case of any overlap)
        for sharedProfile in sharedProfiles {
            if !allProfiles.contains(where: { $0.id == sharedProfile.id }) {
                allProfiles.append(sharedProfile)
            }
        }

        // Sort by name
        self.profiles = allProfiles.sorted { $0.name < $1.name }

        // Validate active profile selection
        validateActiveProfile()
    }
    
    private func validateActiveProfile() {
        // If no active profile is set, use the first one
        if activeProfileId == nil, let firstProfile = profiles.first {
            setActiveProfile(firstProfile)
        }

        // Validate active profile still exists
        if let activeId = activeProfileId,
           !profiles.contains(where: { $0.id == activeId }) {
            // Active profile was deleted, switch to first available
            if let first = profiles.first {
                setActiveProfile(first)
            } else {
                activeProfileId = nil
                saveActiveProfileId()
                NotificationCenter.default.post(name: .activeProfileChanged, object: nil)
            }
        }
    }

    /// Create a new child profile
    func createProfile(
        name: String,
        birthDate: Date,
        gender: Gender,
        allergies: [String]? = nil,
        ownerId: String
    ) {
        var newProfile = ChildProfile(
            ownerId: ownerId,
            name: name,
            birthDate: birthDate,
            gender: gender
        )
        newProfile.knownAllergies = allergies

        Task {
            do {
                try await profileService.add(newProfile)
                // Listener will update 'profiles'
            } catch {
                print("⚠️ Failed to save profile: \(error)")
                // Error handling UI via AppState or binding?
            }
        }
    }

    /// Update an existing profile
    func updateProfile(_ profile: ChildProfile) {
        Task {
            do {
                try await profileService.update(profile)
            } catch {
                print("⚠️ Failed to update profile: \(error)")
            }
        }
    }
    
    /// Update profile with specific fields (convenience)
    func updateProfile(
        _ profile: ChildProfile,
        name: String? = nil,
        birthDate: Date? = nil,
        gender: Gender? = nil,
        allergies: [String]? = nil,
        preferredMode: AppMode? = nil
    ) {
        var updatedProfile = profile
        
        if let name = name { updatedProfile.name = name }
        if let birthDate = birthDate { updatedProfile.birthDate = birthDate }
        if let gender = gender { updatedProfile.gender = gender }
        if let allergies = allergies { updatedProfile.knownAllergies = allergies }
        if let mode = preferredMode { updatedProfile.preferredMode = mode }
        
        updateProfile(updatedProfile)
    }

    /// Delete a profile
    func deleteProfile(_ profile: ChildProfile) {
        guard let id = profile.id else { return }
        
        // Don't allow deleting the last profile logic is UI side, but good safety here too?
        // Let's allow service to delete, validation in UI.

        Task {
            do {
                try await profileService.delete(id: id)
            } catch {
                print("⚠️ Failed to delete profile: \(error)")
            }
        }
        
        // Listener will handle list update and active profile validation
    }

    /// Switch to a different active profile
    func setActiveProfile(_ profile: ChildProfile) {
        guard let id = profile.id else { return }
        
        activeProfileId = id
        saveActiveProfileId()

        // Post notification for app-wide profile change
        NotificationCenter.default.post(name: .activeProfileChanged, object: profile)
    }

    // MARK: - Sibling Comparison (In-Memory for now)

    /// Get growth data for all profiles for comparison
    func getGrowthComparison(for metric: GrowthMetric, growthStore: [GrowthMeasurement]) -> [ProfileGrowthData] {
        // ERROR: Growth logs are in NewbornManager. We need to pass them in or fetch them?
        // Currently GrowthMeasurement has `babyId`. 
        // We can filter the master list provided.
        
        return profiles.map { profile in
            guard let profileId = profile.id else { return ProfileGrowthData(profile: profile, metric: metric, dataPoints: []) }
            
            let profileMeasurements = growthStore.filter { $0.babyId == profileId }
            
            let dataPoints: [(date: Date, value: Double)] = profileMeasurements.compactMap { measurement in
                let value: Double?
                switch metric {
                case .weight: value = measurement.weight
                case .height: value = measurement.height
                case .headCircumference: value = measurement.headCircumference
                }
                
                guard let unwrappedValue = value else { return nil }
                return (date: measurement.date, value: unwrappedValue)
            }
            
            return ProfileGrowthData(
                profile: profile,
                metric: metric,
                dataPoints: dataPoints.sorted(by: { $0.date < $1.date })
            )
        }
    }
    
    /// Get nutrition summaries for all profiles (In-Memory)
    func getNutritionComparison(measurements: [MealLog], allKnownFoods: [FoodItem]) -> [ProfileNutritionData] {
        // Calculate rainbow progress and nutrient counts for all profiles
        // Filter meals by last 7 days
        let last7Days = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentMeals = measurements.filter { $0.timestamp >= last7Days }
        
        return profiles.map { profile in
            // Filter meals for this profile
            let profileMeals = recentMeals.filter { $0.childId == profile.id } // logs must have babyId
            
            var rainbowProgress: [FoodColor: Int] = [:]
            var nutrientCounts: [Nutrient: Int] = [:]
            
            let allFoodIds = profileMeals.flatMap { $0.foods }
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
            
            return ProfileNutritionData(
                profile: profile,
                rainbowProgress: rainbowProgress,
                nutrientCounts: nutrientCounts
            )
        }
    }

    // MARK: - Private Helpers

    private func saveActiveProfileId() {
        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId, forKey: activeProfileKey)
            // Also save to shared UserDefaults for widget access
            WidgetDataManager.saveActiveProfileId(activeId)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
            // Remove from shared UserDefaults as well
            WidgetDataManager.saveActiveProfileId(nil)
        }
    }
}

// MARK: - Supporting Types

enum GrowthMetric {
    case weight
    case height
    case headCircumference
}

struct ProfileNutritionData: Identifiable {
    var id: String { profile.id ?? UUID().uuidString }
    let profile: ChildProfile
    let rainbowProgress: [FoodColor: Int]
    let nutrientCounts: [Nutrient: Int]
}

struct ProfileGrowthData {
    let profile: ChildProfile
    let metric: GrowthMetric
    let dataPoints: [(date: Date, value: Double)]
}

// MARK: - Notification Names

extension Notification.Name {
    static let activeProfileChanged = Notification.Name("activeProfileChanged")
}
