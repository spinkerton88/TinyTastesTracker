import SwiftUI
import SwiftData

struct SleepAndGrowthPage: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    @State private var showingGrowthSheet = false
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Sleep Insights
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Sleep Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            NavigationLink(destination: WeeklyTrendsView()) {
                                HStack(spacing: 4) {
                                    Text("Trends")
                                    Image(systemName: "chart.xyaxis.line")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(appState.themeColor)
                            }
                        }
                        
                        // Statistics from last 24h
                        StatisticsCard(stats: appState.last24HourStats, themeColor: appState.themeColor)
                        
                        // AI Prediction
                        SleepPredictionCard(appState: appState, themeColor: appState.themeColor)
                        
                        // Recent Sleep Sessions
                        VStack(spacing: 12) {
                            if sleepLogs.isEmpty {
                                ContentUnavailableView("No Sleep Logs", systemImage: "moon.zzz", description: Text("Start tracking sleep sessions."))
                                    .frame(height: 150)
                            } else {
                                ForEach(sleepLogs.prefix(5)) { log in
                                    SleepSessionRow(log: log)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // MARK: - Growth Tracking
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Growth Tracking")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                showingGrowthSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(appState.themeColor)
                                .frame(width: 44, height: 44) // Minimum touch target (HIG)
                            }
                        }
                        
                        if appState.growthMeasurements.isEmpty {
                            ContentUnavailableView("No Measurements", systemImage: "ruler", description: Text("Track weight, height, and head circumference."))
                        } else {
                            // Recent Measurements List
                            VStack(spacing: 12) {
                                ForEach(appState.growthMeasurements.sorted { $0.date > $1.date }.prefix(5), id: \.id) { measurement in
                                    GrowthRow(measurement: measurement, userProfile: appState.userProfile)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep & Growth")
            .withSage(context: "User is checking Sleep & Growth insights. Last 24h stats: Feedings, Diapers, Sleep.", appState: appState)
            .sheet(isPresented: $showingGrowthSheet) {
                GrowthTrackingSheet(appState: appState)
            }
        }
    }
}

// MARK: - Sleep Session Row
struct SleepSessionRow: View {
    let log: SleepLog
    
    private var qualityEmoji: String {
        switch log.quality {
        case .excellent: return "😴"
        case .good: return "😊"
        case .fair: return "😐"
        case .poor: return "😟"
        }
    }
    
    private var qualityColor: Color {
        switch log.quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var durationText: String {
        let hours = Int(log.duration / 3600)
        let minutes = Int((log.duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: log.startTime)) - \(formatter.string(from: log.endTime))"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(qualityEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(durationText)
                        .font(.headline)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(log.quality.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(qualityColor)
                }
                
                Text(timeRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Growth Row
struct GrowthRow: View {
    let measurement: GrowthMeasurement
    let userProfile: UserProfile?
    
    private func calculatePercentile(value: Double, metric: String, ageInMonths: Int, gender: Gender) -> Int? {
        guard ageInMonths >= 0 else { return nil }
        
        if metric == "weight" {
            return WHOPercentiles.calculatePercentile(
                value: value,
                ageMonths: ageInMonths,
                metric: .weightForAge,
                gender: gender
            )
        } else if metric == "height" {
            return WHOPercentiles.calculatePercentile(
                value: value,
                ageMonths: ageInMonths,
                metric: .lengthForAge,
                gender: gender
            )
        }
        return nil
    }
    
    private func percentileColor(_ percentile: Int) -> Color {
        switch percentile {
        case ..<3: return .red
        case 3..<15: return .orange
        case 15..<85: return .green
        case 85..<97: return .blue
        default: return .purple
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                if let notes = measurement.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let w = measurement.weight, let profile = userProfile {
                    let ageInMonths = Calendar.current.dateComponents([.month], from: profile.birthDate, to: measurement.date).month ?? 0
                    HStack(spacing: 6) {
                        Text("\(String(format: "%.1f", w)) lbs")
                        if let percentile = calculatePercentile(value: w, metric: "weight", ageInMonths: ageInMonths, gender: profile.gender) {
                            Text("\(percentile)th")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(percentileColor(percentile))
                                .clipShape(Capsule())
                        }
                    }
                }
                if let h = measurement.height, let profile = userProfile {
                    let ageInMonths = Calendar.current.dateComponents([.month], from: profile.birthDate, to: measurement.date).month ?? 0
                    HStack(spacing: 6) {
                        Text("\(String(format: "%.1f", h))\"")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        if let percentile = calculatePercentile(value: h, metric: "height", ageInMonths: ageInMonths, gender: profile.gender) {
                            Text("\(percentile)th")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(percentileColor(percentile))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
