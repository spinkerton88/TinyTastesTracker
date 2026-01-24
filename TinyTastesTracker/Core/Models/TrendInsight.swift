//
//  TrendInsight.swift
//  TinyTastesTracker
//
//  AI-generated trend insights
//

import Foundation

struct TrendInsight: Codable {
    let direction: String  // "increasing", "decreasing", "stable"
    let summary: String    // One-sentence summary
    let causes: [String]   // Likely factors
    let predictions: String  // What to expect
    let recommendations: [String]  // Actionable advice
    let alerts: [String]?  // When to consult pediatrician
}
