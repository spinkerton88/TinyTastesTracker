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
        Task {
            var lastBottleTime: Date?
            var lastNursingTime: Date?
            var lastDiaperTime: Date?
            var lastSleepTime: Date?

            // Try fetching from Firestore if authenticated and have active profile
            if WidgetDataManager.isUserAuthenticated(),
               let profileId = WidgetDataManager.getActiveProfileId() {

                // Fetch recent logs from Firestore
                if let bottleFeeds = try? await WidgetDataManager.fetchRecentBottleFeeds(for: profileId, limit: 1),
                   let latestBottle = bottleFeeds.first {
                    lastBottleTime = latestBottle.timestamp
                }

                if let nursingLogs = try? await WidgetDataManager.fetchRecentNursingLogs(for: profileId, limit: 1),
                   let latestNursing = nursingLogs.first {
                    lastNursingTime = latestNursing.timestamp
                }

                if let diaperLogs = try? await WidgetDataManager.fetchRecentDiaperLogs(for: profileId, limit: 1),
                   let latestDiaper = diaperLogs.first {
                    lastDiaperTime = latestDiaper.timestamp
                }

                if let sleepLogs = try? await WidgetDataManager.fetchRecentSleepLogs(for: profileId, limit: 1),
                   let latestSleep = sleepLogs.first {
                    lastSleepTime = latestSleep.startTime
                }
            }

            // Fallback to UserDefaults or default values
            let entry = QuickLogEntry(
                date: Date(),
                lastBottleTime: lastBottleTime ?? WidgetDataManager.lastLogTime(type: .bottle) ?? Date().addingTimeInterval(-3600),
                lastNursingTime: lastNursingTime ?? WidgetDataManager.lastLogTime(type: .nursing) ?? Date().addingTimeInterval(-7200),
                lastDiaperTime: lastDiaperTime ?? WidgetDataManager.lastLogTime(type: .diaper) ?? Date().addingTimeInterval(-5400),
                lastSleepTime: lastSleepTime ?? WidgetDataManager.lastLogTime(type: .sleep) ?? Date().addingTimeInterval(-10800)
            )

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct QuickLogEntry: TimelineEntry {
    let date: Date
    let lastBottleTime: Date
    let lastNursingTime: Date
    let lastDiaperTime: Date
    let lastSleepTime: Date
}
