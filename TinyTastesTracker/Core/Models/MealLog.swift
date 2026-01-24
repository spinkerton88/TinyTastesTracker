//
//  MealLog.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import SwiftData

enum FeedingStrategy: String, Codable, CaseIterable {
    case none = "None"
    case foodPlay = "Food Play"
    case modeling = "Modeling"
    case divisionOfResponsibility = "Division of Responsibility"
    
    var description: String {
        switch self {
        case .none:
            return "No specific feeding strategy - just a regular meal"
        case .foodPlay:
            return "Encouraging sensory exploration and play with food"
        case .modeling:
            return "Parent/caregiver eating the same foods to demonstrate"
        case .divisionOfResponsibility:
            return "Parent decides what, when, where; child decides if and how much"
        }
    }
}

@Model
final class MealLog: Codable {
    var id: UUID
    var foods: [String]  // Array of food IDs from Constants.allFoods
    var feedingStrategy: FeedingStrategy
    var notes: String
    var platePhotoData: Data?  // Optional photo of the meal
    var timestamp: Date
    var mealType: MealType
    
    init(id: UUID = UUID(),
         foods: [String],
         feedingStrategy: FeedingStrategy = .none,
         notes: String = "",
         platePhotoData: Data? = nil,
         timestamp: Date = Date(),
         mealType: MealType) {
        self.id = id
        self.foods = foods
        self.feedingStrategy = feedingStrategy
        self.notes = notes
        self.platePhotoData = platePhotoData
        self.timestamp = timestamp
        self.mealType = mealType
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, foods, feedingStrategy, notes, platePhotoData, timestamp, mealType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.foods = try container.decode([String].self, forKey: .foods)
        self.feedingStrategy = try container.decode(FeedingStrategy.self, forKey: .feedingStrategy)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.platePhotoData = try container.decodeIfPresent(Data.self, forKey: .platePhotoData)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.mealType = try container.decode(MealType.self, forKey: .mealType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(foods, forKey: .foods)
        try container.encode(feedingStrategy, forKey: .feedingStrategy)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(platePhotoData, forKey: .platePhotoData)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(mealType, forKey: .mealType)
    }
}
