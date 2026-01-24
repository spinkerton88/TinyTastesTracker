import WidgetKit
import SwiftUI

struct SleepSweetSpotProvider: TimelineProvider {
    typealias Entry = SleepSweetSpotEntry

    func placeholder(in context: Context) -> SleepSweetSpotEntry {
        SleepSweetSpotEntry(
            date: Date(),
            prediction: nil,
            isStale: false,
            activeSleepStartTime: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepSweetSpotEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Load sleep prediction data from shared UserDefaults
        let prediction = WidgetDataManager.loadSleepPrediction()
        let isStale = WidgetDataManager.isSleepPredictionStale()
        let activeSleepStartTime = WidgetDataManager.activeSleepStartTime()

        let entry = SleepSweetSpotEntry(
            date: Date(),
            prediction: prediction,
            isStale: isStale,
            activeSleepStartTime: activeSleepStartTime
        )

        // Update timeline based on state
        let nextUpdate: Date
        if activeSleepStartTime != nil {
            // Sleep is active - update every 5 minutes
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        } else if isStale {
            // Prediction is stale - update every hour
            nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        } else if let sweetSpotDate = prediction?.sweetSpotStartDate, sweetSpotDate > Date() {
            // Valid prediction - update when sweet spot arrives or in 15 minutes
            let timeUntilSweetSpot = sweetSpotDate.timeIntervalSince(Date())
            if timeUntilSweetSpot < 15 * 60 {
                nextUpdate = sweetSpotDate
            } else {
                nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            }
        } else {
            // Default: update every 15 minutes
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SleepSweetSpotEntry: TimelineEntry {
    let date: Date
    let prediction: SleepPredictionData?
    let isStale: Bool
    let activeSleepStartTime: Date?

    var sweetSpotStartDate: Date? {
        prediction?.sweetSpotStartDate
    }

    var timeUntilSweetSpot: TimeInterval? {
        guard let sweetSpotDate = sweetSpotStartDate else { return nil }
        let interval = sweetSpotDate.timeIntervalSince(date)
        return interval > 0 ? interval : nil
    }

    var isSleepActive: Bool {
        activeSleepStartTime != nil
    }
}
