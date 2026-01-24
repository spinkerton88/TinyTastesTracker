//
//  ComparisonData.swift
//  TinyTastesTracker
//
//  Data structures for period-over-period comparisons
//

import Foundation

enum ComparisonPeriod: String, CaseIterable {
    case weekOverWeek = "This Week vs Last Week"
    case monthOverMonth = "This Month vs Last Month"
    
    var daysInPeriod: Int {
        switch self {
        case .weekOverWeek: return 7
        case .monthOverMonth: return 30
        }
    }
    
    var shortLabel: String {
        switch self {
        case .weekOverWeek: return "Week"
        case .monthOverMonth: return "Month"
        }
    }
}

struct PeriodComparison<T: Numeric & Comparable> {
    let current: T
    let previous: T
    
    var delta: T {
        current - previous
    }
    
    var percentChange: Double {
        guard let prevNumber = previous as? NSNumber,
              let currNumber = current as? NSNumber else {
            return 0
        }

        let prevDouble = Double(truncating: prevNumber)
        guard prevDouble != 0 else { return 0 }
        let currDouble = Double(truncating: currNumber)
        return ((currDouble - prevDouble) / prevDouble) * 100.0
    }
    
    var isIncreasing: Bool {
        current > previous
    }
    
    var isDecreasing: Bool {
        current < previous
    }
    
    var isStable: Bool {
        current == previous
    }
}

struct FeedingComparison {
    let period: ComparisonPeriod
    let totalFeedings: PeriodComparison<Int>
    let nursingCount: PeriodComparison<Int>
    let bottleCount: PeriodComparison<Int>
    let averagePerDay: PeriodComparison<Double>
    
    var summary: String {
        let direction = totalFeedings.isIncreasing ? "up" : (totalFeedings.isDecreasing ? "down" : "stable")
        let changePercent = abs(totalFeedings.percentChange)
        
        if totalFeedings.isStable {
            return "Feeding patterns are consistent"
        } else {
            return "Total feedings \(direction) \(String(format: "%.0f", changePercent))%"
        }
    }
}

struct SleepComparison {
    let period: ComparisonPeriod
    let totalHours: PeriodComparison<Double>
    let sessionCount: PeriodComparison<Int>
    let averageQuality: PeriodComparison<Double>
    
    var summary: String {
        let direction = totalHours.isIncreasing ? "increased" : (totalHours.isDecreasing ? "decreased" : "stable")
        let hoursChange = abs(totalHours.delta)
        
        if totalHours.isStable {
            return "Sleep duration is consistent"
        } else {
            return "Sleep \(direction) by \(String(format: "%.1f", hoursChange)) hours"
        }
    }
}

struct NutritionComparison {
    let period: ComparisonPeriod
    let totalFoods: PeriodComparison<Int>
    let categoryVariety: PeriodComparison<Int>
    let colorVariety: PeriodComparison<Int>
    
    var summary: String {
        if colorVariety.isIncreasing {
            return "Color variety improved by \(colorVariety.delta) colors"
        } else if colorVariety.isDecreasing {
            return "Color variety decreased by \(abs(colorVariety.delta)) colors"
        } else {
            return "Nutrition variety is consistent"
        }
    }
}
