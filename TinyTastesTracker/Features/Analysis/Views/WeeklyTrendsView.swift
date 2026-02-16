import SwiftUI
import Charts

// Aggregated Data Models
struct DailySleep: Identifiable {
    var id: String { day }
    let day: String
    let hours: Double
}

struct DailyFeed: Identifiable {
    var id: String { day }
    let day: String
    let ounces: Double
}

struct WeeklyTrendsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        List {
            Section("Sleep Trends (Last 7 Days)") {
                Chart(getWeeklySleepData()) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.hours)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .padding(.vertical)
                
                if let avg = getAverageSleep() {
                    LabeledContent("Average Sleep", value: "\(String(format: "%.1f", avg)) hrs/day")
                }
            }
            
            Section("Feeding Trends (Last 7 Days)") {
                Chart(getWeeklyFeedData()) { data in
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Ounces", data.ounces)
                    )
                    .foregroundStyle(Color.pink.gradient)
                    .symbol(by: .value("Type", "Bottle"))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .padding(.vertical)
                
                if let avg = getAverageFeed() {
                    LabeledContent("Average Intake", value: "\(String(format: "%.1f", avg)) oz/day")
                }
            }
        }
        .navigationTitle("Weekly Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Data Helpers
    
    private func getWeeklySleepData() -> [DailySleep] {
        let data = appState.getWeeklySleepData() // defined in AppState
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        // Take last 7 entries or all if less
        return data.suffix(7).map {
            DailySleep(day: formatter.string(from: $0.date), hours: $0.totalHours)
        }
    }
    
    private func getWeeklyFeedData() -> [DailyFeed] {
        let data = appState.getDailyFeedingData(days: 7) // defined in AppState
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        // Note: getDailyFeedingData returns counts, but we want ounces.
        // We'll calculate ounces directly here for accuracy.
        
        var dailyOunces: [DailyFeed] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    continue
                }

                let ounces = appState.bottleFeedLogs
                    .filter { $0.timestamp >= dayStart && $0.timestamp < nextDay }
                    .reduce(0.0) { $0 + $1.amount }

                dailyOunces.append(DailyFeed(day: formatter.string(from: date), ounces: ounces))
            }
        }
        return dailyOunces
    }
    
    private func getAverageSleep() -> Double? {
        let data = getWeeklySleepData()
        guard !data.isEmpty else { return nil }
        return data.map(\.hours).reduce(0, +) / Double(data.count)
    }
    
    private func getAverageFeed() -> Double? {
        let data = getWeeklyFeedData()
        guard !data.isEmpty else { return nil }
        return data.map(\.ounces).reduce(0, +) / Double(data.count)
    }
}

#Preview {
    NavigationStack {
        WeeklyTrendsView()
            .environment(AppState())
    }
}
