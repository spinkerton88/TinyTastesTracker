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
        // Load rainbow progress data from shared UserDefaults
        let progressData = WidgetDataManager.loadRainbowProgress()
        let timeRange = WidgetDataManager.rainbowProgressTimeRange()

        let entry = RainbowProgressEntry(
            date: Date(),
            colorProgress: progressData.isEmpty ? placeholderProgress() : progressData,
            timeRange: timeRange
        )

        // Update every 30 minutes (changes slowly)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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
