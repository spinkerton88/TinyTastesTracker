//
//  WHOPercentiles.swift
//  TinyTastesTracker
//
//  WHO Growth Standards data and percentile calculations
//

import Foundation

enum WHOGrowthMetric {
    case weightForAge      // kg → lbs conversion needed
    case lengthForAge      // cm → inches conversion  
    case headCircForAge    // cm → inches conversion
}

struct WHOPercentileData {
    let ageMonths: Int
    let p3: Double    // 3rd percentile
    let p15: Double   // 15th percentile
    let p50: Double   // 50th percentile (median)
    let p85: Double   // 85th percentile
    let p97: Double   // 97th percentile
}

class WHOPercentiles {
    // MARK: - Boys Weight-for-Age (0-24 months) in kg
    static let boysWeight: [WHOPercentileData] = [
        WHOPercentileData(ageMonths: 0, p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.4),
        WHOPercentileData(ageMonths: 1, p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.1, p97: 5.8),
        WHOPercentileData(ageMonths: 2, p3: 4.3, p15: 4.9, p50: 5.6, p85: 6.3, p97: 7.1),
        WHOPercentileData(ageMonths: 3, p3: 5.0, p15: 5.7, p50: 6.4, p85: 7.2, p97: 8.0),
        WHOPercentileData(ageMonths: 6, p3: 6.4, p15: 7.3, p50: 7.9, p85: 8.8, p97: 9.8),
        WHOPercentileData(ageMonths: 9, p3: 7.1, p15: 8.0, p50: 8.9, p85: 9.9, p97: 10.9),
        WHOPercentileData(ageMonths: 12, p3: 7.7, p15: 8.6, p50: 9.6, p85: 10.8, p97: 11.8),
        WHOPercentileData(ageMonths: 18, p3: 8.8, p15: 9.8, p50: 10.9, p85: 12.3, p97: 13.5),
        WHOPercentileData(ageMonths: 24, p3: 9.7, p15: 10.8, p50: 12.2, p85: 13.6, p97: 15.3)
    ]
    
    // MARK: - Girls Weight-for-Age (0-24 months) in kg
    static let girlsWeight: [WHOPercentileData] = [
        WHOPercentileData(ageMonths: 0, p3: 2.4, p15: 2.8, p50: 3.2, p85: 3.7, p97: 4.2),
        WHOPercentileData(ageMonths: 1, p3: 3.2, p15: 3.6, p50: 4.2, p85: 4.8, p97: 5.5),
        WHOPercentileData(ageMonths: 2, p3: 3.9, p15: 4.5, p50: 5.1, p85: 5.8, p97: 6.6),
        WHOPercentileData(ageMonths: 3, p3: 4.5, p15: 5.2, p50: 5.8, p85: 6.6, p97: 7.5),
        WHOPercentileData(ageMonths: 6, p3: 5.7, p15: 6.5, p50: 7.3, p85: 8.2, p97: 9.3),
        WHOPercentileData(ageMonths: 9, p3: 6.5, p15: 7.3, p50: 8.2, p85: 9.3, p97: 10.5),
        WHOPercentileData(ageMonths: 12, p3: 7.0, p15: 7.9, p50: 8.9, p85: 10.1, p97: 11.3),
        WHOPercentileData(ageMonths: 18, p3: 8.1, p15: 9.1, p50: 10.2, p85: 11.6, p97: 13.0),
        WHOPercentileData(ageMonths: 24, p3: 9.0, p15: 10.2, p50: 11.5, p85: 13.0, p97: 14.8)
    ]
    
    // MARK: - Boys Length-for-Age (0-24 months) in cm
    static let boysLength: [WHOPercentileData] = [
        WHOPercentileData(ageMonths: 0, p3: 46.1, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.7),
        WHOPercentileData(ageMonths: 1, p3: 50.8, p15: 52.8, p50: 54.7, p85: 56.7, p97: 58.6),
        WHOPercentileData(ageMonths: 2, p3: 54.4, p15: 56.4, p50: 58.4, p85: 60.4, p97: 62.4),
        WHOPercentileData(ageMonths: 3, p3: 57.3, p15: 59.4, p50: 61.4, p85: 63.5, p97: 65.5),
        WHOPercentileData(ageMonths: 6, p3: 63.3, p15: 65.5, p50: 67.6, p85: 69.8, p97: 71.9),
        WHOPercentileData(ageMonths: 9, p3: 68.0, p15: 70.1, p50: 72.0, p85: 74.0, p97: 76.0),
        WHOPercentileData(ageMonths: 12, p3: 71.7, p15: 73.9, p50: 75.7, p85: 77.7, p97: 79.8),
        WHOPercentileData(ageMonths: 18, p3: 77.5, p15: 79.8, p50: 82.3, p85: 84.7, p97: 87.0),
        WHOPercentileData(ageMonths: 24, p3: 82.5, p15: 85.1, p50: 87.8, p85: 90.4, p97: 93.0)
    ]
    
    // MARK: - Girls Length-for-Age (0-24 months) in cm
    static let girlsLength: [WHOPercentileData] = [
        WHOPercentileData(ageMonths: 0, p3: 45.4, p15: 47.3, p50: 49.1, p85: 51.0, p97: 52.9),
        WHOPercentileData(ageMonths: 1, p3: 49.8, p15: 51.7, p50: 53.7, p85: 55.6, p97: 57.6),
        WHOPercentileData(ageMonths: 2, p3: 53.0, p15: 55.0, p50: 57.1, p85: 59.1, p97: 61.1),
        WHOPercentileData(ageMonths: 3, p3: 55.6, p15: 57.7, p50: 59.8, p85: 61.9, p97: 64.0),
        WHOPercentileData(ageMonths: 6, p3: 61.2, p15: 63.5, p50: 65.7, p85: 68.0, p97: 70.3),
        WHOPercentileData(ageMonths: 9, p3: 66.1, p15: 68.3, p50: 70.4, p85: 72.6, p97: 74.7),
        WHOPercentileData(ageMonths: 12, p3: 69.8, p15: 72.0, p50: 74.0, p85: 76.1, p97: 78.2),
        WHOPercentileData(ageMonths: 18, p3: 75.9, p15: 78.4, p50: 80.7, p85: 83.2, p97: 85.7),
        WHOPercentileData(ageMonths: 24, p3: 80.9, p15: 83.6, p50: 86.4, p85: 89.1, p97: 91.9)
    ]
    
    // MARK: - Helper Methods
    
    /// Get percentile curve data for charting
    static func getPercentileCurve(
        metric: WHOGrowthMetric,
        gender: Gender,
        percentile: Int  // 3, 15, 50, 85, or 97
    ) -> [(ageMonths: Int, value: Double)] {
        let data: [WHOPercentileData]
        
        switch metric {
        case .weightForAge:
            data = gender == .boy ? boysWeight : girlsWeight
        case .lengthForAge:
            data = gender == .boy ? boysLength : girlsLength
        case .headCircForAge:
            // For simplicity, not implementing head circumference in this version
            return []
        }
        
        return data.map { datum in
            let value: Double
            switch percentile {
            case 3: value = datum.p3
            case 15: value = datum.p15
            case 50: value = datum.p50
            case 85: value = datum.p85
            case 97: value = datum.p97
            default: value = datum.p50
            }
            
            // Convert to imperial units
            let convertedValue: Double
            switch metric {
            case .weightForAge:
                convertedValue = value * 2.20462  // kg to lbs
            case .lengthForAge, .headCircForAge:
                convertedValue = value / 2.54  // cm to inches
            }
            
            return (datum.ageMonths, convertedValue)
        }
    }
    
    /// Calculate approximate percentile for a given value
    static func calculatePercentile(
        value: Double,
        ageMonths: Int,
        metric: WHOGrowthMetric,
        gender: Gender
    ) -> Int {
        let data: [WHOPercentileData]
        
        switch metric {
        case .weightForAge:
            data = gender == .boy ? boysWeight : girlsWeight
        case .lengthForAge:
            data = gender == .boy ? boysLength : girlsLength
        case .headCircForAge:
            return 50  // Default to median
        }
        
        // Find closest age bracket
        guard let datum = data.min(by: { abs($0.ageMonths - ageMonths) < abs($1.ageMonths - ageMonths) }) else {
            return 50
        }
        
        // Convert imperial to metric for comparison
        let metricValue: Double
        switch metric {
        case .weightForAge:
            metricValue = value / 2.20462  // lbs to kg
        case .lengthForAge, .headCircForAge:
            metricValue = value * 2.54  // inches to cm
        }
        
        // Determine percentile range
        if metricValue < datum.p3 { return 1 }
        if metricValue < datum.p15 { return 10 }
        if metricValue < datum.p50 { return 30 }
        if metricValue < datum.p85 { return 65 }
        if metricValue < datum.p97 { return 90 }
        return 98
    }
}
