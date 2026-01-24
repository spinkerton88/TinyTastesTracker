import ActivityKit
import Foundation

struct SleepActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state to update
        var totalDuration: TimeInterval
    }

    // Static data
    var babyName: String
    var startTime: Date
}
