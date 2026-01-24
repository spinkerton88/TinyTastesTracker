//
//  TriedFoodLog.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import SwiftData

enum AllergyReaction: String, Codable {
    case none
    case mild
    case moderate
    case severe
}

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
}

@Model
final class TriedFoodLog: Codable {
    @Attribute(.unique) var id: String  // Food name, matches Constants
    var date: Date
    var reaction: Int  // 1-7 scale
    var meal: MealType
    var allergyReaction: AllergyReaction
    var messyFaceImage: Data?  // Compressed JPEG
    var tryCount: Int
    var reactionSigns: [String] = []  // Specific reactions observed (hives, vomiting, etc.)
    var quantity: String = "bite"  // "taste", "bite", or "serving"
    var isMarkedAsTried: Bool = true
    var unmarkedAt: Date?
    
    init(id: String,
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
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, date, reaction, meal, allergyReaction, messyFaceImage, tryCount, reactionSigns, quantity, isMarkedAsTried, unmarkedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.reaction = try container.decode(Int.self, forKey: .reaction)
        self.meal = try container.decode(MealType.self, forKey: .meal)
        self.allergyReaction = try container.decode(AllergyReaction.self, forKey: .allergyReaction)
        self.messyFaceImage = try container.decodeIfPresent(Data.self, forKey: .messyFaceImage)
        self.tryCount = try container.decode(Int.self, forKey: .tryCount)
        self.reactionSigns = try container.decodeIfPresent([String].self, forKey: .reactionSigns) ?? []
        self.quantity = try container.decodeIfPresent(String.self, forKey: .quantity) ?? "bite"
        self.isMarkedAsTried = try container.decodeIfPresent(Bool.self, forKey: .isMarkedAsTried) ?? true
        self.unmarkedAt = try container.decodeIfPresent(Date.self, forKey: .unmarkedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(reaction, forKey: .reaction)
        try container.encode(meal, forKey: .meal)
        try container.encode(allergyReaction, forKey: .allergyReaction)
        try container.encodeIfPresent(messyFaceImage, forKey: .messyFaceImage)
        try container.encode(tryCount, forKey: .tryCount)
        try container.encode(reactionSigns, forKey: .reactionSigns)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(isMarkedAsTried, forKey: .isMarkedAsTried)
        try container.encodeIfPresent(unmarkedAt, forKey: .unmarkedAt)
    }
}
