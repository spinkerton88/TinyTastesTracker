
//
//  SampleDataGenerator.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 02/06/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

class SampleDataGenerator {
    
    @MainActor
    static func generateSampleData(ownerId: String, appState: AppState) async {
        print("Generating sample data for owner: \(ownerId)")
        
        // 1. Create a Child Profile
        // Create an 8-month old baby for "Explorer" mode relevance (solid foods + milk)
        let birthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
        
        let sampleProfile = ChildProfile(
            ownerId: ownerId,
            name: "Sage",
            birthDate: birthDate,
            gender: .girl,
            knownAllergies: ["Peanuts"],
            preferredMode: .explorer
        )
        
        // Use Firestore directly to bypass Manager limitations and get ID immediately
        let db = Firestore.firestore()
        let childId = UUID().uuidString
        var profileWithId = sampleProfile
        profileWithId.id = childId
        
        let profileRef = db.collection("child_profiles").document(childId)
        
        do {
            try profileRef.setData(from: profileWithId)
            print("Sample profile created with ID: \(childId)")
            
            // Set as active profile preference so it loads on next launch/refresh
            UserDefaults.standard.set(childId, forKey: "ProfileManager.activeProfileId")
            
            // 2. Growth Measurements (3 measurements over time)
            let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            
            try? await appState.newbornManager.saveGrowthMeasurement(
                weight: 16.5,
                height: 26.0,
                headCircumference: 16.8,
                notes: "6-month checkup",
                ownerId: ownerId,
                babyId: childId
            )
            
            try? await appState.newbornManager.saveGrowthMeasurement(
                weight: 17.2,
                height: 26.8,
                headCircumference: 17.0,
                notes: "7-month checkup",
                ownerId: ownerId,
                babyId: childId
            )
            
            try? await appState.newbornManager.saveGrowthMeasurement(
                weight: 18.0,
                height: 27.5,
                headCircumference: 17.2,
                notes: "8-month checkup - growing well!",
                ownerId: ownerId,
                babyId: childId
            )
            
            // 3. Newborn/Sleep Logs
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            
            // Sleep Logs
            try? await appState.newbornManager.saveSleepLog(start: twoDaysAgo, end: twoDaysAgo.addingTimeInterval(3600 * 2), quality: .good, ownerId: ownerId, babyId: childId)
            try? await appState.newbornManager.saveSleepLog(start: yesterday, end: yesterday.addingTimeInterval(3600 * 1.5), quality: .fair, ownerId: ownerId, babyId: childId)
            try? await appState.newbornManager.saveSleepLog(start: Date().addingTimeInterval(-3600 * 3), end: Date().addingTimeInterval(-3600 * 1.5), quality: .excellent, ownerId: ownerId, babyId: childId)

            // Nursing Logs
            try? await appState.newbornManager.saveNursingLog(startTime: Date().addingTimeInterval(-3600 * 4), duration: 1200, side: .left, ownerId: ownerId, babyId: childId)
            try? await appState.newbornManager.saveNursingLog(startTime: Date().addingTimeInterval(-3600 * 8), duration: 900, side: .right, ownerId: ownerId, babyId: childId)
            
            // Diaper Logs - need to use direct Firestore since AppState requires currentChildId
            let diaperLogs = [
                DiaperLog(ownerId: ownerId, babyId: childId, timestamp: Date().addingTimeInterval(-3600 * 2), type: .wet),
                DiaperLog(ownerId: ownerId, babyId: childId, timestamp: Date().addingTimeInterval(-3600 * 5), type: .dirty),
                DiaperLog(ownerId: ownerId, babyId: childId, timestamp: Date().addingTimeInterval(-3600 * 8), type: .both)
            ]
            
            for diaperLog in diaperLogs {
                let diaperRef = db.collection("diaper_logs").document()
                try? diaperRef.setData(from: diaperLog)
            }
            
            // 4. Toddler/Food Logs
            let foodsToLog: [(name: String, reaction: Int)] = [
                ("Sweet Potato", 5),
                ("Avocado", 4),
                ("Banana", 5),
                ("Carrot", 3),
                ("Broccoli", 2),
                ("Blueberry", 5),
                ("Chicken", 4),
                ("Rice", 3)
            ]

            for (foodName, reaction) in foodsToLog {
                let food = appState.allKnownFoods.first(where: { $0.name == foodName })
                let foodId = food?.id ?? foodName.uppercased().replacingOccurrences(of: " ", with: "_")

                let log = TriedFoodLog(
                    ownerId: ownerId,
                    childId: childId,
                    foodId: foodId,
                    foodName: foodName,
                    date: Date().addingTimeInterval(Double.random(in: -86400*7...0)),
                    reaction: reaction,
                    meal: .lunch
                )
                try? await appState.toddlerManager.saveFoodLog(log, ownerId: ownerId, childId: childId)
            }
            
            // 5. Meal Logs (last 3 days)
            let mealDates = [
                Date().addingTimeInterval(-86400 * 2), // 2 days ago
                Date().addingTimeInterval(-86400), // yesterday
                Date() // today
            ]
            
            for mealDate in mealDates {
                // Breakfast
                let breakfastFoods = appState.allKnownFoods.filter { ["Banana", "Avocado"].contains($0.name) }.map { $0.id }
                if !breakfastFoods.isEmpty {
                    let breakfastLog = MealLog(
                        ownerId: ownerId,
                        childId: childId,
                        foods: breakfastFoods,
                        timestamp: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: mealDate) ?? mealDate,
                        mealType: .breakfast
                    )
                    // Save directly to Firestore
                    let mealRef = db.collection("meal_logs").document()
                    try? mealRef.setData(from: breakfastLog)
                }
                
                // Lunch
                let lunchFoods = appState.allKnownFoods.filter { ["Sweet Potato", "Chicken", "Carrot"].contains($0.name) }.map { $0.id }
                if !lunchFoods.isEmpty {
                    let lunchLog = MealLog(
                        ownerId: ownerId,
                        childId: childId,
                        foods: lunchFoods,
                        timestamp: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: mealDate) ?? mealDate,
                        mealType: .lunch
                    )
                    // Save directly to Firestore
                    let mealRef = db.collection("meal_logs").document()
                    try? mealRef.setData(from: lunchLog)
                }
            }
            
            // 6. Sample Recipe
            let sampleRecipe = Recipe(
                ownerId: ownerId,
                title: "Sweet Potato & Banana Mash",
                ingredients: "1 medium sweet potato\n1 ripe banana\n2 tbsp breast milk or formula",
                instructions: "1. Steam sweet potato until soft (15-20 min)\n2. Mash sweet potato with fork\n3. Mash banana separately\n4. Mix together with milk until smooth\n5. Serve at room temperature",
                tags: ["First Foods", "Puree", "Vegetarian"],
                mealTypes: [.breakfast, .snack],
                difficulty: .easy,
                sourceType: .manual
            )
            // Save directly to Firestore
            let recipeRef = db.collection("recipes").document()
            try? recipeRef.setData(from: sampleRecipe)
            
            // 7. Pediatrician Summary
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let endDate = Date()
            
            let sleepMetrics = SleepSummaryMetrics(
                avgNapsPerDay: 2.5,
                avgNapDuration: 5400, // 1.5 hours
                avgTotalSleepTime: 43200, // 12 hours
                longestSleepStretch: 28800, // 8 hours
                totalNaps: 75
            )
            
            let feedingMetrics = FeedingSummaryMetrics(
                avgFeedsPerDay: 5.0,
                avgFeedingInterval: 14400, // 4 hours
                totalFeeds: 150,
                avgBottleVolume: nil,
                avgNursingDuration: 1200 // 20 minutes
            )
            
            let explorerMetrics = ExplorerSummaryMetrics(
                newFoodsTried: 8,
                foodsByColor: [
                    "Orange": 3,
                    "Green": 2,
                    "Yellow": 2,
                    "Purple": 1
                ],
                allergenReactions: 0,
                allergenExposures: []
            )
            
            let diaperMetrics = DiaperSummaryMetrics(
                avgChangesPerDay: 6.5,
                totalChanges: 195,
                wetDiapers: 120,
                dirtyDiapers: 75
            )
            
            let growthMetrics = GrowthSummaryMetrics(
                startWeight: 16.5,
                endWeight: 18.0,
                weightChange: 1.5,
                startHeight: 26.0,
                endHeight: 27.5,
                heightChange: 1.5
            )
            
            let pediatricianSummary = PediatricianSummary(
                ownerId: ownerId,
                childId: childId,
                startDate: startDate,
                endDate: endDate,
                sleepMetrics: sleepMetrics,
                feedingMetrics: feedingMetrics,
                explorerMetrics: explorerMetrics,
                diaperMetrics: diaperMetrics,
                growthMetrics: growthMetrics,
                aiSummary: "Sage is thriving! She's sleeping well with consistent naps and showing excellent growth. Her introduction to solid foods is going smoothly with 8 new foods tried this month. She's particularly enjoying sweet potatoes and bananas. No adverse reactions to allergens noted. Continue current feeding schedule and gradually introduce new textures.",
                highlights: [
                    "Excellent weight gain of 1.5 lbs this month",
                    "Successfully introduced 8 new foods",
                    "Sleeping through the night consistently",
                    "No adverse reactions to allergens"
                ],
                concerns: [
                    "Monitor for signs of peanut allergy (family history)",
                    "Ensure adequate iron intake as she transitions to more solids"
                ],
                suggestedQuestions: [
                    "When should we introduce finger foods?",
                    "How can we encourage self-feeding?",
                    "What are signs of iron deficiency to watch for?"
                ]
            )
            
            // Save pediatrician summary directly to Firestore
            let summaryRef = db.collection("pediatrician_summaries").document()
            try? summaryRef.setData(from: pediatricianSummary)
            
            print("Sample data generation completed.")
            
        } catch {
            print("Error creating sample profile: \(error)")
        }
    }
}
