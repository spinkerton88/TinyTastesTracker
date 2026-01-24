//
//  TrackingDashboardView.swift
//  TinyTastesTracker
//
//  Unified tracking dashboard matching Newborn Log tab aesthetics
//

import SwiftUI
import SwiftData

struct TrackingDashboardView: View {
    let mode: AppMode
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    // Sheet States
    @State private var showingFeedingSheet = false
    @State private var showingSleepSheet = false
    @State private var showingGrowthSheet = false
    @State private var showingMedicationSheet = false
    @State private var showingReportImport = false
    
    // Status State
    @State private var isSleeping = false
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Feed Timer Settings
    @AppStorage("feed_interval_hours") private var feedIntervalHours: Double = 3.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background Header
                LinearGradient(
                    colors: [appState.themeColor.opacity(0.15), appState.themeColor.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Custom Header
                        HStack(alignment: .center) {
                            Text("Tracking")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showingReportImport = true
                            } label: {
                                Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                                .foregroundStyle(appState.themeColor)
                                .padding(8)
                                .background(appState.themeColor.opacity(0.1))
                                .clipShape(Circle())
                            }
                            .accessibilityLabel("Import care provider report")
                            .accessibilityHint("Uploads a schedule from a daycare report")
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - Baby Status Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Baby Status")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(appState.themeColor)
                                
                                Spacer()
                                
                                let currentDate = Date()
                                Text(currentDate.formatted(date: .numeric, time: .omitted))
                                    .font(.caption)
                                    .padding(6)
                                    .background(appState.themeColor.opacity(0.1))
                                    .foregroundStyle(appState.themeColor)
                                    .clipShape(Capsule())
                            }
                            
                            // Status Grid
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // Status Card
                                    StatusCard(
                                        title: "STATUS",
                                        icon: babyStatusIcon,
                                        iconColor: babyStatusColor,
                                        mainText: babyStatusText
                                    )
                                    
                                    // Last Fed Card
                                    StatusCard(
                                        title: "LAST FED",
                                        icon: "drop.fill",
                                        iconColor: appState.themeColor,
                                        mainText: lastFedString
                                    )
                                }
                                
                                HStack(spacing: 12) {
                                    // Last Sleep Card
                                    StatusCard(
                                        title: "LAST SLEEP",
                                        icon: "moon.fill",
                                        iconColor: .indigo,
                                        mainText: lastSleepString
                                    )
                                    
                                    // Next Feed Card
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("NEXT FEED")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                            
                                            // Interval Selector
                                            Menu {
                                                ForEach([2.0, 2.5, 3.0, 3.5, 4.0], id: \.self) { interval in
                                                    Button {
                                                        feedIntervalHours = interval
                                                    } label: {
                                                        HStack {
                                                            Text(formatInterval(interval))
                                                            if feedIntervalHours == interval {
                                                                Image(systemName: "checkmark")
                                                            }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(formatInterval(feedIntervalHours))
                                                    Image(systemName: "chevron.down")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(appState.themeColor.opacity(0.1))
                                                .foregroundStyle(appState.themeColor)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                            .accessibilityLabel("Feed Interval")
                                            .accessibilityValue(formatInterval(feedIntervalHours))
                                            .accessibilityHint("Double tap to change feeding interval")
                                        }
                                        
                                        Text(nextFeedTime)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .accessibilityLabel("Next feed at \(nextFeedTime)")
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                        .background(appState.themeColor.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // MARK: - Action Buttons
                        HStack(spacing: 12) {
                            ActionCapsule(icon: "drop.fill", label: "Feed", color: appState.themeColor) {
                                showingFeedingSheet = true
                            }
                            ActionCapsule(icon: isSleeping ? "moon.zzz.fill" : "moon.fill", label: isSleeping ? "Wake Up" : "Sleep", color: .indigo) {
                                showingSleepSheet = true
                            }
                            ActionCapsule(icon: "chart.line.uptrend.xyaxis", label: "Growth", color: .green) {
                                showingGrowthSheet = true
                            }
                            ActionCapsule(icon: "pills.fill", label: "Meds", color: .mint) {
                                showingMedicationSheet = true
                            }
                        }
                        // MARK: - Today's Logs
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Logs")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            RecentActivityList(appState: appState)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .withSage(
                context: "User is viewing the Tracking tab in \(mode.rawValue.capitalized) mode. They can log feeding, sleep, growth, and medications.",
                appState: appState
            )
            .onAppear {
                isSleeping = WidgetDataManager.activeSleepStartTime() != nil
            }
            .onChange(of: feedIntervalHours) { _, _ in
                appState.rescheduleFeedNotification()
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                isSleeping = WidgetDataManager.activeSleepStartTime() != nil
            }
            .sheet(isPresented: $showingFeedingSheet) {
                FeedingSheet(appState: appState)
            }
            .sheet(isPresented: $showingSleepSheet) {
                SleepLogSheet(appState: appState)
            }
            .onChange(of: showingSleepSheet) { _, isPresented in
                if !isPresented {
                    // Refresh sleep status when sheet is dismissed
                    isSleeping = WidgetDataManager.activeSleepStartTime() != nil
                }
            }
            .sheet(isPresented: $showingGrowthSheet) {
                GrowthTrackingSheet(appState: appState)
            }
            .sheet(isPresented: $showingMedicationSheet) {
                MedicationSheet(appState: appState)
            }
            .sheet(isPresented: $showingReportImport) {
            ReportImportView(themeColor: appState.themeColor)
        }
        }
    }
    
    // MARK: - Computed Properties
    
    var babyStatusText: String {
        if isSleeping {
            return "Sleeping"
        }
        
        if let lastSleep = appState.sleepLogs.sorted(by: { $0.endTime < $1.endTime }).last {
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
    
    var lastFedString: String {
        let lastBottle = appState.bottleFeedLogs.last
        let lastNursing = appState.nursingLogs.last
        
        var lastTime: Date?
        if let b = lastBottle, let n = lastNursing {
            lastTime = b.timestamp > n.timestamp ? b.timestamp : n.timestamp
        } else {
            lastTime = lastBottle?.timestamp ?? lastNursing?.timestamp
        }
        
        guard let last = lastTime else { return "Ready" }
        return last.formatted(date: .omitted, time: .shortened)
    }
    
    var lastSleepString: String {
        guard let last = appState.sleepLogs.last else { return "Ready" }
        return last.startTime.formatted(date: .omitted, time: .shortened)
    }
    
    var nextFeedTime: String {
        // Find last feed (Bottle or Nursing)
        let lastBottle = appState.bottleFeedLogs.sorted { $0.timestamp < $1.timestamp }.last
        let lastNursing = appState.nursingLogs.sorted { $0.timestamp < $1.timestamp }.last
        
        var lastTime: Date?
        if let b = lastBottle, let n = lastNursing {
            lastTime = b.timestamp > n.timestamp ? b.timestamp : n.timestamp
        } else {
            lastTime = lastBottle?.timestamp ?? lastNursing?.timestamp
        }
        
        guard let last = lastTime else { return "Ready" }
        let next = last.addingTimeInterval(feedIntervalHours * 3600)
        return next.formatted(date: .omitted, time: .shortened)
    }
    
    func formatInterval(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)h \(m)m"
        }
    }
}
