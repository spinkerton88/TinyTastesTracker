//
//  SharedModelContainer.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 01/18/26.
//

import SwiftData
import Foundation

class SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            UserAccount.self,
            Badge.self,
            Milestone.self,

            // Toddler Mode
            MealLog.self,
            TriedFoodLog.self,
            CustomFood.self,
            NutrientGoals.self,
            Recipe.self,
            MealPlanEntry.self,
            ShoppingListItem.self,

            // Newborn Mode
            NursingLog.self,
            BottleFeedLog.self,
            DiaperLog.self,
            SleepLog.self,
            PumpingLog.self,
            MedicationLog.self,
            GrowthMeasurement.self,
            ActivityLog.self,

            // Health
            PediatricianSummary.self
        ])
        
        // Try CloudKit first, fall back immediately if it fails
        // IMPORTANT: No async/await or semaphores - this runs on main thread during app launch
        print("🔄 Initializing ModelContainer...")
        
        do {
            // Try CloudKit configuration
            let cloudKitConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let container = try ModelContainer(for: schema, configurations: [cloudKitConfig])
            print("✅ Successfully created ModelContainer with CloudKit sync enabled")
            return container
            
        } catch {
            // CloudKit failed - fall back to local storage immediately
            print("⚠️ CloudKit initialization failed: \(error.localizedDescription)")
            print("📱 Falling back to local-only storage...")
            
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                print("✅ Successfully created ModelContainer with local storage")
                print("⚠️ Data will NOT sync across devices")
                return container
                
            } catch let localError {
                // Local storage failed - try in-memory as last resort
                print("❌ Local storage failed: \(localError.localizedDescription)")
                print("🆘 Using in-memory storage as last resort...")
                
                do {
                    let memoryConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    print("⚠️ Using IN-MEMORY storage - data will be lost on restart!")
                    return container
                } catch {
                    fatalError("Could not create ModelContainer: \(localError)")
                }
            }
        }
    }()
}
