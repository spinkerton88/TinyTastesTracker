//
//  TrendAnalyzer.swift
//  TinyTastesTracker
//
//  Statistical trend analysis and prediction utilities
//

import Foundation

struct TrendPrediction {
    let futurePoint: (date: Date, value: Double)
    let confidence: Double  // 0.0 to 1.0
    let isReliable: Bool    // Based on data quantity and variance
}

struct TrendAnalysis {
    let direction: TrendDirection
    let strength: Double  // 0.0 to 1.0
    let predictions: [TrendPrediction]
    let recommendation: String
}

enum TrendDirection: String {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
    case insufficient = "Insufficient Data"
}

class TrendAnalyzer {
    
    // MARK: - Linear Regression
    
    /// Perform simple linear regression on time-series data
    static func predictLinearTrend(
        dataPoints: [(date: Date, value: Double)],
        futureDays: Int = 14
    ) -> [TrendPrediction] {
        guard dataPoints.count >= 3 else { return [] }
        
        // Convert dates to days since first measurement
        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        guard let firstDate = sortedPoints.first?.date else { return [] }
        
        let numericPoints: [(x: Double, y: Double)] = sortedPoints.map { point in
            let daysSinceStart = point.date.timeIntervalSince(firstDate) / (24 * 3600)
            return (daysSinceStart, point.value)
        }
        
        // Calculate linear regression parameters
        let n = Double(numericPoints.count)
        let sumX = numericPoints.reduce(0.0) { $0 + $1.x }
        let sumY = numericPoints.reduce(0.0) { $0 + $1.y }
        let sumXY = numericPoints.reduce(0.0) { $0 + ($1.x * $1.y) }
        let sumX2 = numericPoints.reduce(0.0) { $0 + ($1.x * $1.x) }
        
        // Slope and intercept
        let denominator = (n * sumX2 - sumX * sumX)
        guard denominator != 0 else { return [] }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        // Calculate R² for confidence
        let meanY = sumY / n
        let ssTotal = numericPoints.reduce(0.0) { $0 + pow($1.y - meanY, 2) }
        let ssResidual = numericPoints.reduce(0.0) { result, point in
            let predicted = slope * point.x + intercept
            return result + pow(point.y - predicted, 2)
        }
        let rSquared = 1 - (ssResidual / ssTotal)
        
        // Generate predictions
        guard let lastDate = sortedPoints.last?.date,
              let lastX = numericPoints.last?.x else { return [] }
        
        var predictions: [TrendPrediction] = []
        
        for day in 1...futureDays {
            let futureX = lastX + Double(day)
            let predictedValue = slope * futureX + intercept
            
            // Confidence decreases with distance and improves with R²
            let distanceDecay = pow(0.92, Double(day))  // 8% decay per day
            let dataQualityBonus = min(1.0, Double(dataPoints.count) / 10.0)
            let baseConfidence = rSquared * dataQualityBonus
            let confidence = baseConfidence * distanceDecay
            
            let futureDate = Calendar.current.date(byAdding: .day, value: day, to: lastDate) ?? lastDate
            
            predictions.append(TrendPrediction(
                futurePoint: (futureDate, max(0, predictedValue)),  // No negative values
                confidence: max(0.1, min(0.9, confidence)),
                isReliable: dataPoints.count >= 5 && rSquared > 0.5
            ))
        }
        
        return predictions
    }
    
    // MARK: - Trend Direction Analysis
    
    static func analyzeTrendDirection(
        dataPoints: [(date: Date, value: Double)]
    ) -> TrendAnalysis {
        guard dataPoints.count >= 3 else {
            return TrendAnalysis(
                direction: .insufficient,
                strength: 0.0,
                predictions: [],
                recommendation: "Add more measurements to see trends"
            )
        }
        
        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        
        // Calculate slope using first and last points
        guard let firstValue = sortedPoints.first?.value,
              let lastValue = sortedPoints.last?.value,
              let firstDate = sortedPoints.first?.date,
              let lastDate = sortedPoints.last?.date else {
            return TrendAnalysis(
                direction: .insufficient,
                strength: 0.0,
                predictions: [],
                recommendation: "Invalid data"
            )
        }
        
        let timeSpan = lastDate.timeIntervalSince(firstDate) / (24 * 3600)  // in days
        guard timeSpan > 0 else {
            return TrendAnalysis(
                direction: .stable,
                strength: 0.0,
                predictions: [],
                recommendation: "Need measurements across multiple days"
            )
        }
        
        let changePerDay = (lastValue - firstValue) / timeSpan
        let percentChange = (lastValue - firstValue) / firstValue * 100.0
        
        // Determine direction
        let direction: TrendDirection
        if abs(percentChange) < 2.0 {  // Less than 2% change
            direction = .stable
        } else if changePerDay > 0 {
            direction = .increasing
        } else {
            direction = .decreasing
        }
        
        // Calculate strength (0.0 to 1.0)
        let strength = min(1.0, abs(percentChange) / 50.0)  // Normalize to 50% change
        
        // Generate predictions
        let predictions = predictLinearTrend(dataPoints: dataPoints, futureDays: 14)
        
        // Generate recommendation
        let recommendation = generateRecommendation(
            direction: direction,
            percentChange: percentChange,
            dataCount: dataPoints.count
        )
        
        return TrendAnalysis(
            direction: direction,
            strength: strength,
            predictions: predictions,
            recommendation: recommendation
        )
    }
    
    // MARK: - Recommendations
    
    private static func generateRecommendation(
        direction: TrendDirection,
        percentChange: Double,
        dataCount: Int
    ) -> String {
        switch direction {
        case .increasing:
            if percentChange > 20 {
                return "Rapid growth detected. This is typically healthy for infants."
            } else {
                return "Steady growth trend. Continue current feeding patterns."
            }
            
        case .decreasing:
            if abs(percentChange) > 10 {
                return "Consult your pediatrician about this declining trend."
            } else {
                return "Slight decrease observed. Monitor closely over the next week."
            }
            
        case .stable:
            if dataCount < 5 {
                return "Add more measurements to detect trends."
            } else {
                return "Growth is stable. Maintain current routines."
            }
            
        case .insufficient:
            return "Add at least 3 measurements to see trends."
        }
    }
    
    // MARK: - Confidence Intervals
    
    static func calculateConfidenceInterval(
        prediction: TrendPrediction,
        standardError: Double = 0.1
    ) -> (lower: Double, upper: Double) {
        // Simple confidence interval (± 1.96 * SE for 95% CI)
        let interval = 1.96 * standardError * (1.0 - prediction.confidence + 0.5)
        return (
            lower: max(0, prediction.futurePoint.value - interval),
            upper: prediction.futurePoint.value + interval
        )
    }
}
