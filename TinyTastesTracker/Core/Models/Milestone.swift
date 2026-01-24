//
//  Milestone.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import Foundation
import SwiftData

@Model
final class Milestone: Codable {
    var id: UUID
    var title: String
    var category: AppMode
    var isCompleted: Bool
    var dateCompleted: Date?
    var icon: String
    
    init(id: UUID = UUID(),
         title: String,
         category: AppMode,
         isCompleted: Bool = false,
         dateCompleted: Date? = nil,
         icon: String) {
        self.id = id
        self.title = title
        self.category = category
        self.isCompleted = isCompleted
        self.dateCompleted = dateCompleted
        self.icon = icon
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, title, category, isCompleted, dateCompleted, icon
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.category = try container.decode(AppMode.self, forKey: .category)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.dateCompleted = try container.decodeIfPresent(Date.self, forKey: .dateCompleted)
        self.icon = try container.decode(String.self, forKey: .icon)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(dateCompleted, forKey: .dateCompleted)
        try container.encode(icon, forKey: .icon)
    }
    
    static func defaults() -> [Milestone] {
        return [
            // Newborn (0-6 Months)
            Milestone(title: "First Smile", category: .newborn, icon: "face.smiling"),
            Milestone(title: "Holds Head Up", category: .newborn, icon: "figure.stand"),
            Milestone(title: "Rolls Over (Tummy to Back)", category: .newborn, icon: "arrow.uturn.left"),
            Milestone(title: "Rolls Over (Back to Tummy)", category: .newborn, icon: "arrow.uturn.right"),
            Milestone(title: "Grabs Objects", category: .newborn, icon: "hand.raised"),
            Milestone(title: "Tracks with Eyes", category: .newborn, icon: "eye"),
            Milestone(title: "Laughs Out Loud", category: .newborn, icon: "mouth"),
            
            // Explorer (6-12 Months)
            Milestone(title: "Sits Unassisted", category: .explorer, icon: "chair.lounge"),
            Milestone(title: "First Taste (Solids)", category: .explorer, icon: "carrot"),
            Milestone(title: "Self-Feeding (Finger Foods)", category: .explorer, icon: "hand.point.up.left"),
            Milestone(title: "Pincer Grasp", category: .explorer, icon: "hand.draw"),
            Milestone(title: "Open Cup (Assisted)", category: .explorer, icon: "mug"),
            Milestone(title: "Straw Cup", category: .explorer, icon: "cup.and.saucer"),
            Milestone(title: "Spoon Master (Attempts)", category: .explorer, icon: "fork.knife"),
            
            // Toddler (12+ Months)
            Milestone(title: "Walks Unassisted", category: .toddler, icon: "figure.walk"),
            Milestone(title: "Uses Spoon/Fork Independently", category: .toddler, icon: "fork.knife.circle"),
            Milestone(title: "Drinks from Open Cup (One Hand)", category: .toddler, icon: "mug.fill"),
            Milestone(title: "Says First Word", category: .toddler, icon: "bubble.left"),
            Milestone(title: "Tries New Food (No Fuss)", category: .toddler, icon: "star"),
            Milestone(title: "Helps Clean Up", category: .toddler, icon: "trash"),
            Milestone(title: "Stacks Blocks", category: .toddler, icon: "square.stack.3d.down.right")
        ]
    }
}
