import WidgetKit
import SwiftUI

struct QuickLogProvider: TimelineProvider {
    typealias Entry = QuickLogEntry

    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(
            date: Date(),
            lastBottleTime: Date().addingTimeInterval(-3600),
            lastNursingTime: Date().addingTimeInterval(-7200),
            lastDiaperTime: Date().addingTimeInterval(-5400),
            lastSleepTime: Date().addingTimeInterval(-10800)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch last log times from shared UserDefaults
        let lastBottleTime = WidgetDataManager.lastLogTime(type: .bottle) ?? Date().addingTimeInterval(-3600)
        let lastNursingTime = WidgetDataManager.lastLogTime(type: .nursing) ?? Date().addingTimeInterval(-7200)
        let lastDiaperTime = WidgetDataManager.lastLogTime(type: .diaper) ?? Date().addingTimeInterval(-5400)
        let lastSleepTime = WidgetDataManager.lastLogTime(type: .sleep) ?? Date().addingTimeInterval(-10800)

        let entry = QuickLogEntry(
            date: Date(),
            lastBottleTime: lastBottleTime,
            lastNursingTime: lastNursingTime,
            lastDiaperTime: lastDiaperTime,
            lastSleepTime: lastSleepTime
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickLogEntry: TimelineEntry {
    let date: Date
    let lastBottleTime: Date
    let lastNursingTime: Date
    let lastDiaperTime: Date
    let lastSleepTime: Date
}
