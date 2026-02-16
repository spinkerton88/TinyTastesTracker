//
//  TriedFoodLog.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum AllergyReaction: String, Codable {
    case none
    case mild
    case moderate
    case severe
}

// Ensure MealType is only defined once if it's shared. 
// However, in the original file, MealType was defined inside TriedFoodLog.swift. 
// MealLog also used it. It might be defined in multiple places or shared.
// Given MealLog used MealType.lunch, and TriedFoodLog defined it,
// I should keep the definition here or check if it conflicts. 
// Assuming it was valid Swift code before, it's either shared or defined here.
// I'll keep it here as it was in the original file.
enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
}

struct TriedFoodLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var childId: String // Tried foods are specific to a child

    var foodId: String // The food's unique ID (e.g., "AVOCADO")
    var foodName: String // The food's display name (e.g., "Avocado")

    var date: Date = Date()
    var reaction: Int = 1 // 1-7 scale
    var meal: MealType = MealType.lunch
    var allergyReaction: AllergyReaction = AllergyReaction.none
    var messyFaceImage: Data?  // Compressed JPEG
    var tryCount: Int = 0
    var reactionSigns: [String] = []  // Specific reactions observed (hives, vomiting, etc.)
    var quantity: String = "bite"  // "taste", "bite", or "serving"
    var isMarkedAsTried: Bool = true
    var unmarkedAt: Date?

    init(id: String? = nil,
         ownerId: String,
         childId: String,
         foodId: String,
         foodName: String,
         date: Date = Date(),
         reaction: Int,
         meal: MealType,
         allergyReaction: AllergyReaction = .none,
         messyFaceImage: Data? = nil,
         tryCount: Int = 1,
         reactionSigns: [String] = [],
         quantity: String = "bite",
         isMarkedAsTried: Bool = true,
         unmarkedAt: Date? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.childId = childId
        self.foodId = foodId
        self.foodName = foodName
        self.date = date
        self.reaction = reaction
        self.meal = meal
        self.allergyReaction = allergyReaction
        self.messyFaceImage = messyFaceImage
        self.tryCount = tryCount
        self.reactionSigns = reactionSigns
        self.quantity = quantity
        self.isMarkedAsTried = isMarkedAsTried
        self.unmarkedAt = unmarkedAt
    }
}
