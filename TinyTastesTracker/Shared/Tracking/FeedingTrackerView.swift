//
//  FeedingTrackerView.swift
//  TinyTastesTracker
//
//  Shared component for feeding tracking across all modes
//

import SwiftUI
import SwiftData

struct FeedingTrackerView: View {
    let mode: AppMode
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingFeedingSheet = false
    
    // Get last feeding log
    var lastFeeding: String {
        if let lastNursing = appState.nursingLogs.last {
            return "Nursed \(formatDuration(lastNursing.duration)) (\(lastNursing.side.rawValue))"
        } else if let lastBottle = appState.bottleFeedLogs.last {
            let formatted = String(format: "%.1f", lastBottle.amount)
            return "Bottle: \(formatted)oz"
        } else if let lastPumping = appState.pumpingLogs.last {
            let formatted = String(format: "%.1f", lastPumping.totalYield)
            return "Pumped: \(formatted)oz total"
        }
        return "No feedings logged yet"
    }
    
    var lastFeedingTime: String {
        let logs: [Date] = [
            appState.nursingLogs.last?.timestamp,
            appState.bottleFeedLogs.last?.timestamp,
            appState.pumpingLogs.last?.timestamp
        ].compactMap { $0 }
        
        guard let mostRecent = logs.max() else {
            return ""
        }
        
        return formatRelativeTime(from: mostRecent)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Feeding")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !lastFeedingTime.isEmpty {
                    Text(lastFeedingTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Last feeding summary
            if !appState.nursingLogs.isEmpty || !appState.bottleFeedLogs.isEmpty || !appState.pumpingLogs.isEmpty {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(appState.themeColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Feed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastFeeding)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last feed: \(lastFeeding)")
                .accessibilityHint("Shows the most recent feeding details")
            }
            
            // Log feeding button
            Button(action: { showingFeedingSheet = true }) {
                HStack {
                    Image(systemName: getFeedingIcon())
                    Text(getFeedingButtonText())
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(getFeedingButtonText())
            .accessibilityHint("Double tap to log a new feeding")
            
            // Recent feeding list (compact)
            if !appState.nursingLogs.isEmpty || !appState.bottleFeedLogs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Feeds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    
                    ForEach(Array(getRecentFeedings().prefix(3)), id: \.id) { item in
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundStyle(appState.themeColor.opacity(0.7))
                                .frame(width: 20)
                            
                            Text(item.description)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(item.time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.description) at \(item.time)")
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingFeedingSheet) {
            FeedingSheet(appState: appState)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFeedingIcon() -> String {
        switch mode {
        case .newborn:
            return "heart.fill"
        case .explorer:
            return "drop.triangle.fill"
        case .toddler:
            return "fork.knife"
        }
    }
    
    private func getFeedingButtonText() -> String {
        switch mode {
        case .newborn:
            return "Log Feeding"
        case .explorer:
            return "Log Feeding"
        case .toddler:
            return "Log Meal/Feeding"
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
    
    private func getRecentFeedings() -> [FeedingItem] {
        var items: [FeedingItem] = []
        
        // Add nursing logs
        for log in appState.nursingLogs.suffix(5) {
            items.append(FeedingItem(
                id: log.id.uuidString,
                icon: "heart.fill",
                description: "Nursed \(formatDuration(log.duration)) (\(log.side.rawValue))",
                time: log.timestamp.formatted(date: .omitted, time: .shortened),
                timestamp: log.timestamp
            ))
        }
        
        // Add bottle feeds
        for log in appState.bottleFeedLogs.suffix(5) {
            let formatted = String(format: "%.1f", log.amount)
            items.append(FeedingItem(
                id: log.id.uuidString,
                icon: "drop.triangle.fill",
                description: "Bottle: \(formatted)oz",
                time: log.timestamp.formatted(date: .omitted, time: .shortened),
                timestamp: log.timestamp
            ))
        }
        
        // Add pumping logs
        for log in appState.pumpingLogs.suffix(5) {
            let formatted = String(format: "%.1f", log.totalYield)
            items.append(FeedingItem(
                id: log.id.uuidString,
                icon: "drop.fill",
                description: "Pumped: \(formatted)oz",
                time: log.timestamp.formatted(date: .omitted, time: .shortened),
                timestamp: log.timestamp
            ))
        }
        
        // Sort by timestamp (most recent first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
}

struct FeedingItem: Identifiable {
    let id: String
    let icon: String
    let description: String
    let time: String
    let timestamp: Date
}
