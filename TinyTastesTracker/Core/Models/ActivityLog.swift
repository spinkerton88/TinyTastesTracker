//
//  ActivityLog.swift
//  TinyTastesTracker
//
//  Model for general activity and milestone logs
//

import Foundation
import SwiftData

@Model
class ActivityLog {
    var timestamp: Date
    var activityType: String // "play", "mood", "milestone", "other"
    var activityDescription: String
    var notes: String?
    
    init(
        timestamp: Date,
        activityType: String,
        description: String,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.activityType = activityType
        self.activityDescription = description
        self.notes = notes
    }
}
