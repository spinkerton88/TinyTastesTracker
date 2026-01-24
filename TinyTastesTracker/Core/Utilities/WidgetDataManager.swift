//
//  WidgetDataManager.swift
//  TinyTastesTracker
//
//  Shared utility for managing widget data communication between app and widget extension.
//  This file must be included in both the main app target and the widget extension target.
//

import Foundation
import WidgetKit

/// Centralized manager for widget data storage and retrieval
/// Uses App Groups UserDefaults for sharing data between app and widget extension
struct WidgetDataManager {
    // MARK: - Constants

    /// App Group identifier - must match entitlements configuration
    static let suiteName = "group.com.tinytastes.tracker"

    /// Shared UserDefaults instance
    private static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        // Sleep Sweet Spot Widget
        static let lastSleepPrediction = "lastSleepPrediction"
        static let lastSleepPredictionTime = "lastSleepPredictionTime"
        static let activeSleepStartTime = "activeSleepStartTime"

        // Rainbow Progress Widget
        static let rainbowProgressData = "rainbowProgressData"
        static let rainbowProgressLastUpdate = "rainbowProgressLastUpdate"
        static let rainbowProgressTimeRange = "rainbowProgressTimeRange"

        // Quick Log Widget
        static let widgetNursingLogRequest = "widgetNursingLogRequest"
        static let widgetDiaperLogRequest = "widgetDiaperLogRequest"
        static let widgetSleepLogRequest = "widgetSleepLogRequest"
        static let lastBottleTime = "lastBottleTime"
        static let lastNursingTime = "lastNursingTime"
        static let lastDiaperTime = "lastDiaperTime"
        static let lastSleepTime = "lastSleepTime"
    }

    // MARK: - Sleep Sweet Spot Widget

    /// Save sleep prediction data for widget display
    static func saveSleepPrediction(_ prediction: SleepPredictionData) {
        guard let defaults = shared else { return }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(prediction) {
            defaults.set(encoded, forKey: Keys.lastSleepPrediction)
            defaults.set(Date(), forKey: Keys.lastSleepPredictionTime)
            reloadSleepWidgets()
        }
    }

    /// Load sleep prediction data
    static func loadSleepPrediction() -> SleepPredictionData? {
        guard let defaults = shared,
              let data = defaults.data(forKey: Keys.lastSleepPrediction) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(SleepPredictionData.self, from: data)
    }

    /// Get the timestamp of the last sleep prediction
    static func lastSleepPredictionTime() -> Date? {
        shared?.object(forKey: Keys.lastSleepPredictionTime) as? Date
    }

    /// Check if sleep prediction is stale (>6 hours old)
    static func isSleepPredictionStale() -> Bool {
        guard let predictionTime = lastSleepPredictionTime() else { return true }
        return Date().timeIntervalSince(predictionTime) > (6 * 3600)
    }

    /// Save active sleep start time (when sleep timer is running)
    static func setActiveSleepStartTime(_ date: Date?) {
        if let date = date {
            shared?.set(date, forKey: Keys.activeSleepStartTime)
        } else {
            shared?.removeObject(forKey: Keys.activeSleepStartTime)
        }
        reloadSleepWidgets()
    }

    /// Get active sleep start time
    static func activeSleepStartTime() -> Date? {
        shared?.object(forKey: Keys.activeSleepStartTime) as? Date
    }

    // MARK: - Rainbow Progress Widget

    /// Save rainbow progress data for widget display
    static func saveRainbowProgress(_ progress: [ColorProgressData], timeRange: String = "week") {
        guard let defaults = shared else { return }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(progress) {
            defaults.set(encoded, forKey: Keys.rainbowProgressData)
            defaults.set(Date(), forKey: Keys.rainbowProgressLastUpdate)
            defaults.set(timeRange, forKey: Keys.rainbowProgressTimeRange)
            reloadRainbowWidgets()
        }
    }

    /// Load rainbow progress data
    static func loadRainbowProgress() -> [ColorProgressData] {
        guard let defaults = shared,
              let data = defaults.data(forKey: Keys.rainbowProgressData) else {
            return []
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode([ColorProgressData].self, from: data)) ?? []
    }

    /// Get the time range for rainbow progress (day, week, month)
    static func rainbowProgressTimeRange() -> String {
        shared?.string(forKey: Keys.rainbowProgressTimeRange) ?? "week"
    }

    /// Get last update time for rainbow progress
    static func rainbowProgressLastUpdate() -> Date? {
        shared?.object(forKey: Keys.rainbowProgressLastUpdate) as? Date
    }

    // MARK: - Quick Log Widget

    /// Save timestamp when a log was created (for display context in widget)
    static func saveLastLogTime(type: LogType, time: Date) {
        guard let defaults = shared else { return }

        let key: String
        switch type {
        case .bottle:
            key = Keys.lastBottleTime
        case .nursing:
            key = Keys.lastNursingTime
        case .diaper:
            key = Keys.lastDiaperTime
        case .sleep:
            key = Keys.lastSleepTime
        }

        defaults.set(time, forKey: key)
        reloadQuickLogWidgets()
    }

    /// Get last log time for a specific type
    static func lastLogTime(type: LogType) -> Date? {
        guard let defaults = shared else { return nil }

        let key: String
        switch type {
        case .bottle:
            key = Keys.lastBottleTime
        case .nursing:
            key = Keys.lastNursingTime
        case .diaper:
            key = Keys.lastDiaperTime
        case .sleep:
            key = Keys.lastSleepTime
        }

        return defaults.object(forKey: key) as? Date
    }

    /// Set a log request flag (widget wants app to log something)
    static func setLogRequest(type: LogType) {
        guard let defaults = shared else { return }

        let key: String
        switch type {
        case .bottle:
            return // Existing key handled elsewhere
        case .nursing:
            key = Keys.widgetNursingLogRequest
        case .diaper:
            key = Keys.widgetDiaperLogRequest
        case .sleep:
            key = Keys.widgetSleepLogRequest
        }

        defaults.set(Date(), forKey: key)
    }

    /// Check and consume log request flags
    static func consumeLogRequest(type: LogType) -> Date? {
        guard let defaults = shared else { return nil }

        let key: String
        switch type {
        case .bottle:
            return nil // Existing key handled elsewhere
        case .nursing:
            key = Keys.widgetNursingLogRequest
        case .diaper:
            key = Keys.widgetDiaperLogRequest
        case .sleep:
            key = Keys.widgetSleepLogRequest
        }

        let date = defaults.object(forKey: key) as? Date
        if date != nil {
            defaults.removeObject(forKey: key)
        }
        return date
    }

    // MARK: - Widget Refresh

    /// Reload all sleep-related widgets
    static func reloadSleepWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "SleepSweetSpotWidget")
    }

    /// Reload all rainbow progress widgets
    static func reloadRainbowWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "RainbowProgressWidget")
    }

    /// Reload all quick log widgets
    static func reloadQuickLogWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "QuickLogWidget")
    }

    /// Reload all widgets
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Data Models

/// Sleep prediction data for widget display
struct SleepPredictionData: Codable {
    let predictionStatus: String
    let nextSweetSpotStart: String?
    let nextSweetSpotEnd: String?
    let confidence: String
    let reasoning: String

    /// Parse sweet spot start time
    var sweetSpotStartDate: Date? {
        guard let startString = nextSweetSpotStart else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: startString)
    }
}

/// Color progress data for rainbow widget
struct ColorProgressData: Codable, Identifiable {
    let id: String
    let color: String
    let count: Int
    let goal: Int

    var percentage: Double {
        Double(count) / Double(goal)
    }

    var metGoal: Bool {
        count >= goal
    }

    /// Initialize from FoodColor and count
    init(color: FoodColor, count: Int, goal: Int = 7) {
        self.id = color.rawValue
        self.color = color.rawValue
        self.count = count
        self.goal = goal
    }

    /// Codable initializer (required for JSON decoding)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.color = try container.decode(String.self, forKey: .color)
        self.count = try container.decode(Int.self, forKey: .count)
        self.goal = try container.decode(Int.self, forKey: .goal)
    }

    /// Codable encoder (required for JSON encoding)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(color, forKey: .color)
        try container.encode(count, forKey: .count)
        try container.encode(goal, forKey: .goal)
    }

    private enum CodingKeys: String, CodingKey {
        case id, color, count, goal
    }
}

/// Log types for quick log widget
enum LogType {
    case bottle
    case nursing
    case diaper
    case sleep
}

// FoodColor enum is now included from Constants.swift in both targets
