//
//  NutrientGoals.swift
//  TinyTastesTracker
//
//  Data model for custom nutrient goals
//

import Foundation
import SwiftData

@Model
final class NutrientGoals: Codable {
    @Attribute(.unique) var id: UUID
    var userId: UUID  // Link to UserProfile
    var createdDate: Date
    var lastModified: Date
    
    // Weekly serving goals for each nutrient
    var ironGoal: Int
    var calciumGoal: Int
    var vitaminCGoal: Int
    var omega3Goal: Int
    var proteinGoal: Int
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        ironGoal: Int = 5,
        calciumGoal: Int = 7,
        vitaminCGoal: Int = 7,
        omega3Goal: Int = 3,
        proteinGoal: Int = 14
    ) {
        self.id = id
        self.userId = userId
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
    func setGoal(for nutrient: Nutrient, value: Int) {
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
    func resetToDefaults() {
        ironGoal = 5
        calciumGoal = 7
        vitaminCGoal = 7
        omega3Goal = 3
        proteinGoal = 14
        lastModified = Date()
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, userId, createdDate, lastModified
        case ironGoal, calciumGoal, vitaminCGoal, omega3Goal, proteinGoal
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.createdDate = try container.decode(Date.self, forKey: .createdDate)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.ironGoal = try container.decode(Int.self, forKey: .ironGoal)
        self.calciumGoal = try container.decode(Int.self, forKey: .calciumGoal)
        self.vitaminCGoal = try container.decode(Int.self, forKey: .vitaminCGoal)
        self.omega3Goal = try container.decode(Int.self, forKey: .omega3Goal)
        self.proteinGoal = try container.decode(Int.self, forKey: .proteinGoal)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(ironGoal, forKey: .ironGoal)
        try container.encode(calciumGoal, forKey: .calciumGoal)
        try container.encode(vitaminCGoal, forKey: .vitaminCGoal)
        try container.encode(omega3Goal, forKey: .omega3Goal)
        try container.encode(proteinGoal, forKey: .proteinGoal)
    }
}
