
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
            
            // 2. Newborn/Sleep Logs
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            
            // Sleep Logs
            let sleep1 = SleepLog(ownerId: ownerId, babyId: childId, startTime: twoDaysAgo, endTime: twoDaysAgo.addingTimeInterval(3600 * 2), quality: .good)
            let sleep2 = SleepLog(ownerId: ownerId, babyId: childId, startTime: yesterday, endTime: yesterday.addingTimeInterval(3600 * 1.5), quality: .fair)
            
            // Use AppState managers to save (they wrap Firestore calls)
            try? await appState.newbornManager.saveSleepLog(start: sleep1.startTime, end: sleep1.endTime, quality: sleep1.quality, ownerId: ownerId, babyId: childId)
            try? await appState.newbornManager.saveSleepLog(start: sleep2.startTime, end: sleep2.endTime, quality: sleep2.quality, ownerId: ownerId, babyId: childId)

            // Nursing Logs
            try? await appState.newbornManager.saveNursingLog(startTime: Date().addingTimeInterval(-3600 * 4), duration: 1200, side: .left, ownerId: ownerId, babyId: childId)
            
            // 3. Toddler/Food Logs
            // Add some known foods and logs
            let foodsToLog: [(name: String, reaction: Int)] = [
                ("Sweet Potato", 5),
                ("Avocado", 4),
                ("Banana", 5),
                ("Carrot", 3),
                ("Broccoli", 2)
            ]

            for (foodName, reaction) in foodsToLog {
                // Find the food ID by name from allKnownFoods
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
            
            print("Sample data generation completed.")
            
        } catch {
            print("Error creating sample profile: \(error)")
        }
    }
}
