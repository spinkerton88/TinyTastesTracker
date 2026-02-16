//
//  AnalyticsService.swift
//  TinyTastesTracker
//
//  Privacy-focused analytics tracking for onboarding and feature discovery
//

import Foundation
import FirebaseAnalytics

/// Analytics service for tracking user behavior and onboarding metrics
/// Note: This is a local-only implementation. For production, integrate with
/// TelemetryDeck, Firebase Analytics, or similar privacy-focused service.
class AnalyticsService {
    
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    /// Track a generic event
    func track(event: AnalyticsEvent, properties: [String: Any]? = nil) {
        let timestamp = Date()
        let eventData: [String: Any] = [
            "event": event.rawValue,
            "timestamp": timestamp.ISO8601Format(),
            "properties": properties ?? [:]
        ]

        // Log to console for debugging
        print("📊 Analytics: \(event.rawValue)")
        if let props = properties {
            print("   Properties: \(props)")
        }

        // Store locally for metrics
        storeEvent(eventData)

        // Send to Firebase Analytics
        if let props = properties {
            Analytics.logEvent(event.rawValue, parameters: props)
        } else {
            Analytics.logEvent(event.rawValue, parameters: nil)
        }
    }
    
    // MARK: - Onboarding Events
    
    func trackOnboardingStarted() {
        track(event: .onboardingStarted)
        UserDefaults.standard.set(Date(), forKey: "onboardingStartTime")
    }
    
    func trackOnboardingCompleted(usedSampleData: Bool) {
        let startTime = UserDefaults.standard.object(forKey: "onboardingStartTime") as? Date
        let duration = startTime.map { Date().timeIntervalSince($0) }
        
        track(event: .onboardingCompleted, properties: [
            "used_sample_data": usedSampleData,
            "duration_seconds": duration ?? 0
        ])
    }
    
    func trackOnboardingSkipped() {
        track(event: .onboardingSkipped)
    }
    
    func trackModeSelected(mode: String) {
        track(event: .modeSelected, properties: ["mode": mode])
    }
    
    func trackProfileCreated(ageInMonths: Int, gender: String) {
        track(event: .profileCreated, properties: [
            "age_months": ageInMonths,
            "gender": gender
        ])
    }
    
    // MARK: - Feature Tour Events
    
    func trackFeatureTourStarted() {
        track(event: .featureTourStarted)
        UserDefaults.standard.set(Date(), forKey: "featureTourStartTime")
    }
    
    func trackFeatureTourCompleted() {
        let startTime = UserDefaults.standard.object(forKey: "featureTourStartTime") as? Date
        let duration = startTime.map { Date().timeIntervalSince($0) }
        
        track(event: .featureTourCompleted, properties: [
            "duration_seconds": duration ?? 0
        ])
    }
    
    func trackFeatureTourSkipped(atPage: Int, totalPages: Int) {
        track(event: .featureTourSkipped, properties: [
            "page": atPage,
            "total_pages": totalPages,
            "completion_percentage": Double(atPage) / Double(totalPages) * 100
        ])
    }
    
    func trackFeatureTourPageViewed(page: Int, featureName: String) {
        track(event: .featureTourPageViewed, properties: [
            "page": page,
            "feature": featureName
        ])
    }
    
    // MARK: - Feature Discovery Events
    
    func trackFeatureDiscovered(feature: String, timeToDiscover: TimeInterval? = nil) {
        var properties: [String: Any] = ["feature": feature]
        if let time = timeToDiscover {
            properties["time_to_discover_seconds"] = time
        }
        track(event: .featureDiscovered, properties: properties)
    }
    
    func trackFirstTimeAction(action: String) {
        let key = "firstTime_\(action)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        
        UserDefaults.standard.set(true, forKey: key)
        track(event: .firstTimeAction, properties: ["action": action])
    }
    
    // MARK: - Sample Data Events
    
    func trackSampleDataLoaded(source: String) {
        track(event: .sampleDataLoaded, properties: ["source": source])
    }
    
    func trackSampleDataCleared() {
        track(event: .sampleDataCleared)
    }
    
    // MARK: - Onboarding Validation Events
    
    func trackOnboardingValidationError(errorType: String) {
        track(event: .onboardingValidationError, properties: ["error_type": errorType])
    }
    
    func trackOnboardingDropOff(step: String) {
        track(event: .onboardingDropOff, properties: ["step": step])
    }
    
    // MARK: - Local Storage
    
    private func storeEvent(_ eventData: [String: Any]) {
        var events = UserDefaults.standard.array(forKey: "analyticsEvents") as? [[String: Any]] ?? []
        events.append(eventData)
        
        // Keep only last 100 events
        if events.count > 100 {
            events = Array(events.suffix(100))
        }
        
        UserDefaults.standard.set(events, forKey: "analyticsEvents")
    }
    
    // MARK: - Analytics Retrieval
    
    func getStoredEvents() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "analyticsEvents") as? [[String: Any]] ?? []
    }
    
    func clearStoredEvents() {
        UserDefaults.standard.removeObject(forKey: "analyticsEvents")
    }
    
    // MARK: - Metrics
    
    func getOnboardingMetrics() -> OnboardingMetrics {
        let events = getStoredEvents()
        
        let onboardingStarted = events.filter { ($0["event"] as? String) == AnalyticsEvent.onboardingStarted.rawValue }.count
        let onboardingCompleted = events.filter { ($0["event"] as? String) == AnalyticsEvent.onboardingCompleted.rawValue }.count
        let usedSampleData = events.filter {
            guard let event = $0["event"] as? String,
                  event == AnalyticsEvent.onboardingCompleted.rawValue,
                  let props = $0["properties"] as? [String: Any],
                  let used = props["used_sample_data"] as? Bool else { return false }
            return used
        }.count
        
        let completionRate = onboardingStarted > 0 ? Double(onboardingCompleted) / Double(onboardingStarted) : 0
        let sampleDataRate = onboardingCompleted > 0 ? Double(usedSampleData) / Double(onboardingCompleted) : 0
        
        return OnboardingMetrics(
            started: onboardingStarted,
            completed: onboardingCompleted,
            completionRate: completionRate,
            sampleDataRate: sampleDataRate
        )
    }
}

// MARK: - Supporting Types

enum AnalyticsEvent: String {
    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case modeSelected = "mode_selected"
    case profileCreated = "profile_created"
    case onboardingValidationError = "onboarding_validation_error"
    case onboardingDropOff = "onboarding_drop_off"
    
    // Feature Tour
    case featureTourStarted = "feature_tour_started"
    case featureTourCompleted = "feature_tour_completed"
    case featureTourSkipped = "feature_tour_skipped"
    case featureTourPageViewed = "feature_tour_page_viewed"
    
    // Feature Discovery
    case featureDiscovered = "feature_discovered"
    case firstTimeAction = "first_time_action"
    
    // Sample Data
    case sampleDataLoaded = "sample_data_loaded"
    case sampleDataCleared = "sample_data_cleared"
}

struct OnboardingMetrics {
    let started: Int
    let completed: Int
    let completionRate: Double
    let sampleDataRate: Double
}
