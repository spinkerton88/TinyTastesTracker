import WidgetKit
import SwiftUI

struct RainbowProgressProvider: TimelineProvider {
    typealias Entry = RainbowProgressEntry

    func placeholder(in context: Context) -> RainbowProgressEntry {
        RainbowProgressEntry(
            date: Date(),
            colorProgress: placeholderProgress(),
            timeRange: "week"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RainbowProgressEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var progressData: [ColorProgressData] = []
            let timeRange = WidgetDataManager.rainbowProgressTimeRange()

            // Try fetching from Firestore if authenticated and have active profile
            if WidgetDataManager.isUserAuthenticated(),
               let profileId = WidgetDataManager.getActiveProfileId() {

                // Calculate date range based on timeRange setting
                let calendar = Calendar.current
                let now = Date()
                let startDate: Date

                switch timeRange {
                case "day":
                    startDate = calendar.startOfDay(for: now)
                case "month":
                    startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                default: // "week"
                    startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                }

                // Fetch meal logs from Firestore
                if let mealLogs = try? await WidgetDataManager.fetchRecentMealLogs(for: profileId, since: startDate) {
                    progressData = WidgetDataManager.calculateRainbowProgress(from: mealLogs)
                }
            }

            // Fallback to UserDefaults if Firestore fetch failed or no auth
            if progressData.isEmpty {
                progressData = WidgetDataManager.loadRainbowProgress()
            }

            // Use placeholder if still no data
            if progressData.isEmpty {
                progressData = placeholderProgress()
            }

            let entry = RainbowProgressEntry(
                date: Date(),
                colorProgress: progressData,
                timeRange: timeRange
            )

            // Update every 30 minutes (changes slowly)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func placeholderProgress() -> [ColorProgressData] {
        FoodColor.allCases.map { color in
            ColorProgressData(color: color, count: Int.random(in: 0...7), goal: 7)
        }
    }
}

struct RainbowProgressEntry: TimelineEntry {
    let date: Date
    let colorProgress: [ColorProgressData]
    let timeRange: String

    var achievedColorCount: Int {
        colorProgress.filter { $0.metGoal }.count
    }

    var totalColorGoal: Int {
        colorProgress.count
    }
}
