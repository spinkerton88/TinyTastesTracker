//
//  UserProfile.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import SwiftData

enum AppMode: String, Codable {
    case newborn = "NEWBORN"
    case explorer = "EXPLORER"
    case toddler = "TODDLER"
}

enum Gender: String, Codable {
    case boy
    case girl
    case other
}

@Model
final class UserProfile: Codable {
    @Attribute(.unique) var id: UUID
    var babyName: String
    var birthDate: Date
    var gender: Gender
    var knownAllergies: [String]?
    var preferredMode: AppMode?
    @Transient var milestones: [Milestone]? = []
    @Transient var badges: [Badge]? = []
    
    init(id: UUID = UUID(),
         babyName: String,
         birthDate: Date,
         gender: Gender,
         knownAllergies: [String]? = nil,
         preferredMode: AppMode? = nil) {
        self.id = id
        self.babyName = babyName
        self.birthDate = birthDate
        self.gender = gender
        self.knownAllergies = knownAllergies
        self.preferredMode = preferredMode
        self.milestones = Milestone.defaults()
        self.badges = Badge.defaults()
//        self.substitutedFoods = [:]
    }

    
    @Transient var substitutedFoods: [String: String]? = [:] // Map of OriginalFoodID -> SubstitutedFoodID
    
    // MARK: - Computed Properties
    
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }
    
    var currentMode: AppMode {
        if let preferredMode = preferredMode {
            return preferredMode
        }
        
        switch ageInMonths {
        case 0..<6:
            return .newborn
        case 6..<12:
            return .explorer
        default:
            return .toddler
        }
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, babyName, birthDate, gender, knownAllergies, preferredMode, milestones, badges, substitutedFoods
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.babyName = try container.decode(String.self, forKey: .babyName)
        self.birthDate = try container.decode(Date.self, forKey: .birthDate)
        self.gender = try container.decode(Gender.self, forKey: .gender)
        self.knownAllergies = try container.decodeIfPresent([String].self, forKey: .knownAllergies)
        self.preferredMode = try container.decodeIfPresent(AppMode.self, forKey: .preferredMode)
        self.milestones = try container.decodeIfPresent([Milestone].self, forKey: .milestones) ?? Milestone.defaults()
        self.badges = try container.decodeIfPresent([Badge].self, forKey: .badges) ?? Badge.defaults()
        self.substitutedFoods = try container.decodeIfPresent([String: String].self, forKey: .substitutedFoods) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(babyName, forKey: .babyName)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(knownAllergies, forKey: .knownAllergies)
        try container.encodeIfPresent(preferredMode, forKey: .preferredMode)
        try container.encodeIfPresent(milestones, forKey: .milestones)
        try container.encodeIfPresent(badges, forKey: .badges)
        try container.encodeIfPresent(substitutedFoods, forKey: .substitutedFoods)
    }
}
