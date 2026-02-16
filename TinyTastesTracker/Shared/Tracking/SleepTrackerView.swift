//
//  SleepTrackerView.swift
//  TinyTastesTracker
//
//  Shared component for sleep tracking across all modes
//

import SwiftUI

struct SleepTrackerView: View {
    let mode: AppMode
    @Bindable var appState: AppState
    @State private var showingSleepSheet = false
    @State private var isSleeping = false
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var showPredictions: Bool {
        // Show predictions for Newborn and Explorer modes
        mode == .newborn || mode == .explorer
    }
    
    var lastSleep: String {
        guard let lastSleepLog = appState.sleepLogs.last else {
            return "No sleep logged yet"
        }
        
        let duration = lastSleepLog.duration
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
   var lastSleepTime: String {
        guard let lastSleepLog = appState.sleepLogs.last else {
            return ""
        }
        return formatRelativeTime(from: lastSleepLog.endTime)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Sleep")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !lastSleepTime.isEmpty {
                    Text(lastSleepTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Baby Status (for all modes)
            HStack {
                Image(systemName: babyStatusIcon)
                    .foregroundStyle(babyStatusColor.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Baby Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(babyStatusText)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Last sleep summary
            if !appState.sleepLogs.isEmpty {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(appState.themeColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Sleep")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastSleep)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last sleep: \(lastSleep)")
            }
            
            // Sleep predictions (for Newborn/Explorer)
            if showPredictions {
                SleepPredictionCard(appState: appState, themeColor: appState.themeColor)
            }
            
            // Log sleep button
            Button(action: { showingSleepSheet = true }) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                    Text("Log Sleep")
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Log Sleep")
            .accessibilityHint("Double tap to log sleep duration")
            
            // Recent sleep list
            if !appState.sleepLogs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sleep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(Array(appState.sleepLogs.suffix(3).reversed()), id: \.id) { log in
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(appState.themeColor.opacity(0.7))
                                .frame(width: 20)
                            
                            Text(formatSleepDuration(log.duration))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(log.startTime.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingSleepSheet) {
            SleepLogSheet(appState: appState)
        }
        .onAppear {
            isSleeping = WidgetDataManager.activeSleepStartTime() != nil
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            isSleeping = WidgetDataManager.activeSleepStartTime() != nil
        }
        .onChange(of: showingSleepSheet) { _, isPresented in
            if !isPresented {
                // Refresh sleep status when sheet is dismissed
                isSleeping = WidgetDataManager.activeSleepStartTime() != nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatSleepDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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
    
    // MARK: - Baby Status Computed Properties
    
    var babyStatusText: String {
        // 1. Check active sleep timer first (Live Activity)
        if isSleeping {
            return "Sleeping"
        }
        
        // 2. Check traditional logs (fallback)
        if let lastSleep = appState.sleepLogs.sorted(by: { $0.endTime < $1.endTime }).last {
            // Check if endTime is in the future (still sleeping)
            if lastSleep.endTime > currentTime {
                return "Sleeping"
            }
        }
        return "Awake"
    }
    
    var babyStatusIcon: String {
        babyStatusText == "Sleeping" ? "moon.fill" : "sun.max.fill"
    }
    
    var babyStatusColor: Color {
        babyStatusText == "Sleeping" ? .indigo : .yellow
    }
}
