//
//  PediatricianSummary.swift
//  TinyTastesTracker
//
//  Data model for health visit summaries
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PediatricianSummary: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var childId: String
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    
    // Relationship - Handled by ID referencing in Firestore if needed, but here we just store the summary data.
    // var userProfile: UserProfile? // Removed direct relationship, rely on ownerId

    // Aggregated Metrics
    var sleepMetrics: SleepSummaryMetrics
    var feedingMetrics: FeedingSummaryMetrics
    var explorerMetrics: ExplorerSummaryMetrics?
    var medicationMetrics: MedicationSummaryMetrics?
    var diaperMetrics: DiaperSummaryMetrics
    var growthMetrics: GrowthSummaryMetrics?

    // AI-Generated Content
    var aiSummary: String
    var highlights: [String]
    var concerns: [String]
    var suggestedQuestions: [String]

    // Parent Notes
    var parentNotes: String?

    // Export
    var pdfURL: URL?

    init(
        id: String? = nil,
        ownerId: String,
        childId: String,
        startDate: Date,
        endDate: Date,
        sleepMetrics: SleepSummaryMetrics,
        feedingMetrics: FeedingSummaryMetrics,
        explorerMetrics: ExplorerSummaryMetrics? = nil,
        medicationMetrics: MedicationSummaryMetrics? = nil,
        diaperMetrics: DiaperSummaryMetrics,
        growthMetrics: GrowthSummaryMetrics? = nil,
        aiSummary: String,
        highlights: [String],
        concerns: [String],
        suggestedQuestions: [String]
    ) {
        self.id = id
        self.ownerId = ownerId
        self.childId = childId
        self.startDate = startDate
        self.endDate = endDate
        self.generatedAt = Date()
        self.sleepMetrics = sleepMetrics
        self.feedingMetrics = feedingMetrics
        self.explorerMetrics = explorerMetrics
        self.medicationMetrics = medicationMetrics
        self.diaperMetrics = diaperMetrics
        self.growthMetrics = growthMetrics
        self.aiSummary = aiSummary
        self.highlights = highlights
        self.concerns = concerns
        self.suggestedQuestions = suggestedQuestions
    }
}

// MARK: - Metrics Structures

struct SleepSummaryMetrics: Codable {
    var avgNapsPerDay: Double
    var avgNapDuration: TimeInterval
    var avgTotalSleepTime: TimeInterval
    var longestSleepStretch: TimeInterval
    var totalNaps: Int
}

struct FeedingSummaryMetrics: Codable {
    var avgFeedsPerDay: Double
    var avgFeedingInterval: TimeInterval
    var totalFeeds: Int
    var avgBottleVolume: Double?
    var avgNursingDuration: TimeInterval?
}

struct ExplorerSummaryMetrics: Codable {
    var newFoodsTried: Int
    var foodsByColor: [String: Int] // Rainbow tracking
    var allergenReactions: Int
    var allergenExposures: [String]
}

struct MedicationSummaryMetrics: Codable {
    var avgDosesPerDay: Double
    var medications: [String]
    var totalDoses: Int
}

struct DiaperSummaryMetrics: Codable {
    var avgChangesPerDay: Double
    var totalChanges: Int
    var wetDiapers: Int
    var dirtyDiapers: Int
}

struct GrowthSummaryMetrics: Codable {
    var startWeight: Double?
    var endWeight: Double?
    var weightChange: Double?
    var startHeight: Double?
    var endHeight: Double?
    var heightChange: Double?
}
