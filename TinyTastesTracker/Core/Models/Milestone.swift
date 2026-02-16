//
//  Milestone.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 2/4/26.
//

import Foundation

struct Milestone: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var category: AppMode
    var isCompleted: Bool
    var dateCompleted: Date?
    var icon: String
    
    init(id: String = UUID().uuidString,
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
