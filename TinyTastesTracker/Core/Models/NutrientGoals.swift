//
//  NutrientGoals.swift
//  TinyTastesTracker
//
//  Data model for custom nutrient goals
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct NutrientGoals: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var childId: String
    
    var createdDate: Date
    var lastModified: Date
    
    // Weekly serving goals for each nutrient
    var ironGoal: Int
    var calciumGoal: Int
    var vitaminCGoal: Int
    var omega3Goal: Int
    var proteinGoal: Int
    
    init(
        id: String? = nil,
        ownerId: String,
        childId: String,
        ironGoal: Int = 5,
        calciumGoal: Int = 7,
        vitaminCGoal: Int = 7,
        omega3Goal: Int = 3,
        proteinGoal: Int = 14
    ) {
        self.id = id
        self.ownerId = ownerId
        self.childId = childId
        self.createdDate = Date()
        self.lastModified = Date()
        self.ironGoal = ironGoal
        self.calciumGoal = calciumGoal
        self.vitaminCGoal = vitaminCGoal
        self.omega3Goal = omega3Goal
        self.proteinGoal = proteinGoal
    }
    
    // MARK: - Helpers
    
    /// Get goal for a specific nutrient
    func getGoal(for nutrient: Nutrient) -> Int {
        switch nutrient {
        case .iron: return ironGoal
        case .calcium: return calciumGoal
        case .vitaminC: return vitaminCGoal
        case .omega3: return omega3Goal
        case .protein: return proteinGoal
        }
    }
    
    /// Set goal for a specific nutrient
    mutating func setGoal(for nutrient: Nutrient, value: Int) {
        switch nutrient {
        case .iron: ironGoal = value
        case .calcium: calciumGoal = value
        case .vitaminC: vitaminCGoal = value
        case .omega3: omega3Goal = value
        case .protein: proteinGoal = value
        }
        lastModified = Date()
    }
    
    /// Default WHO-recommended goals
    static var defaultGoals: [Nutrient: Int] {
        [
            .iron: 5,        // ~0.7 servings/day
            .calcium: 7,     // 1 serving/day
            .vitaminC: 7,    // 1 serving/day
            .omega3: 3,      // ~0.4 servings/day
            .protein: 14     // 2 servings/day
        ]
    }
    
    /// Reset to default values
    mutating func resetToDefaults() {
        ironGoal = 5
        calciumGoal = 7
        vitaminCGoal = 7
        omega3Goal = 3
        proteinGoal = 14
        lastModified = Date()
    }
}
