//
//  ChartDataModels.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI
//

import Foundation

// MARK: - Time Range Filter

enum TimeRange: String, CaseIterable {
    case day = "24h"
    case week = "Week"
    case month = "Month"
    case all = "All"
    
    var days: Int? {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .all: return nil
        }
    }
}

// MARK: - Feeding Data

struct DailyFeedingData: Identifiable {
    let id = UUID()
    let date: Date
    let nursingCount: Int
    let bottleCount: Int
    let totalCount: Int
    
    init(date: Date, nursingCount: Int, bottleCount: Int) {
        self.date = date
        self.nursingCount = nursingCount
        self.bottleCount = bottleCount
        self.totalCount = nursingCount + bottleCount
    }
}

// MARK: - Category Distribution

struct CategoryDistribution: Identifiable {
    let id: String
    let category: String
    let count: Int
    let percentage: Double
    let color: FoodColor
}

// MARK: - Nutrient Progress

struct NutrientProgress: Identifiable {
    let id: Nutrient
    let name: String
    let count: Int
    let weeklyGoal: Int
    
    var metGoal: Bool {
        count >= weeklyGoal
    }
    
    var percentage: Double {
        Double(count) / Double(weeklyGoal)
    }
}

// MARK: - Sleep Data

struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let sessionCount: Int
    let averageQuality: Double // 1-4 scale
}

struct SleepSession: Identifiable {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    let quality: SleepQuality
    
    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }
    
    var durationHours: Double {
        duration / 3600.0
    }
}

// MARK: - Rainbow Progress

struct ColorProgress: Identifiable {
    let id: FoodColor
    let color: FoodColor
    let count: Int
    let goal: Int
    
    var percentage: Double {
        Double(count) / Double(goal)
    }
    
    var metGoal: Bool {
        count >= goal
    }
}

// MARK: - Growth Data Point

struct GrowthDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let weight: Double?
    let height: Double?
    let headCircumference: Double?
}
