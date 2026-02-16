//
//  MealLog.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

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

struct MealLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var childId: String
    
    var foods: [String] = []  // Array of food IDs from Constants.allFoods
    var feedingStrategy: FeedingStrategy = FeedingStrategy.none
    var notes: String = ""
    var platePhotoData: Data?  // Optional photo of the meal
    var timestamp: Date = Date()
    var mealType: MealType = MealType.lunch
    
    // Explicit init allows creating instances without Firestore decoding
    init(id: String? = nil,
         ownerId: String,
         childId: String,
         foods: [String],
         feedingStrategy: FeedingStrategy = .none,
         notes: String = "",
         platePhotoData: Data? = nil,
         timestamp: Date = Date(),
         mealType: MealType) {
        self.id = id
        self.ownerId = ownerId
        self.childId = childId
        self.foods = foods
        self.feedingStrategy = feedingStrategy
        self.notes = notes
        self.platePhotoData = platePhotoData
        self.timestamp = timestamp
        self.mealType = mealType
    }
    
    // Customize coding keys if needed (usually not needed for simple properties, 
    // but good for checking exact mapping)
    // CodingKeys can be omitted if property names match field names exactly. 
    // Usually Firestore uses camelCase which matches Swift properties.
}
