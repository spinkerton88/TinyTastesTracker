import SwiftUI
import SwiftData

struct NewbornDashboardPage: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    // Sheet States
    @State private var showingFeedingSheet = false
    @State private var showingSleepSheet = false
    @State private var showingDiaperSelection = false
    @State private var showingMedicationSheet = false
    @State private var showingReportImport = false
    
    // Status State
    @State private var isSleeping = false
    
    // Feed Timer Settings
    @AppStorage("feed_interval_hours") private var feedIntervalHours: Double = 3.0
    
    // Timer for updating "Next Feed" and "Status" every minute
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background Header
                LinearGradient(
                    colors: [Color.pink.opacity(0.15), Color.pink.opacity(0.05), Color.clear],
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
                                .foregroundStyle(Color.pink)
                                .padding(8)
                                .background(Color.pink.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Import care provider report")
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: - Baby Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Baby Status")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.pink) // Or theme color
                            
                            Spacer()
                            
                            let currentDate = Date()
                            Text(currentDate.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .padding(6)
                                .background(Color.pink.opacity(0.1))
                                .foregroundStyle(Color.pink)
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
                                            .background(Color.pink.opacity(0.1))
                                            .foregroundStyle(.pink)
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
                            
                            HStack(spacing: 12) {
                                // Last Fed Card
                                StatusCard(
                                    title: "LAST FED",
                                    icon: "drop.fill", // Bottle icon
                                    iconColor: .pink,
                                    mainText: lastFedString
                                )
                                
                                // Last Diaper Card
                                StatusCard(
                                    title: "LAST DIAPER",
                                    icon: "face.smiling", // Placeholder
                                    iconColor: .blue,
                                    mainText: lastDiaperString
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.pink.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // MARK: - Action Buttons
                    HStack(spacing: 12) {
                        ActionCapsule(icon: "drop.fill", label: "Feed", color: .pink) {
                            showingFeedingSheet = true
                        }
                        ActionCapsule(icon: "drop.triangle.fill", label: "Diaper", color: .blue) {
                            showingDiaperSelection = true
                        }
                        ActionCapsule(icon: isSleeping ? "moon.zzz.fill" : "moon.fill", label: isSleeping ? "Wake Up" : "Sleep", color: .indigo) {
                            showingSleepSheet = true
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
                    .background(.ultraThinMaterial) // Or card style
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            }
            .navigationTitle("Dashboard") // Or hidden
            .withSage(context: "User is on Newborn Dashboard. Next feed: \(nextFeedTime). Last: \(lastFedString) (Fed), \(lastDiaperString) (Diaper).", appState: appState)
            .navigationBarHidden(true)
            .onAppear {
                isSleeping = WidgetDataManager.activeSleepStartTime() != nil
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                isSleeping = WidgetDataManager.activeSleepStartTime() != nil
            }
            .onChange(of: feedIntervalHours) { _, _ in
                appState.rescheduleFeedNotification()
            }
            .sheet(isPresented: $showingFeedingSheet) {
                 FeedingSheet(appState: appState)
            }
            .sheet(isPresented: $showingSleepSheet) {
                SleepLogSheet(appState: appState)
            }
            .onChange(of: showingSleepSheet) { _, isPresented in
                if !isPresented {
                    // Update current time to ensure fallback logic is accurate
                    currentTime = Date()
                    // Refresh sleep status when sheet is dismissed
                    isSleeping = WidgetDataManager.activeSleepStartTime() != nil
                }
            }
            .confirmationDialog("Log Diaper Change", isPresented: $showingDiaperSelection) {
                Button("Wet") {
                    HapticManager.impact()
                    appState.saveDiaperLog(type: .wet, context: modelContext)
                    HapticManager.success()
                }
                Button("Dirty") {
                    HapticManager.impact()
                    appState.saveDiaperLog(type: .dirty, context: modelContext)
                    HapticManager.success()
                }
                Button("Both") {
                    HapticManager.impact()
                    appState.saveDiaperLog(type: .both, context: modelContext)
                    HapticManager.success()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingMedicationSheet) {
                MedicationSheet(appState: appState)
            }
        .sheet(isPresented: $showingReportImport) {
            ReportImportView(themeColor: .pink)
        }
        }
    }
    
    // MARK: - Logic Helpers
    
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
    
    var nextFeedTimeRemaining: String {
        let lastBottle = appState.bottleFeedLogs.sorted { $0.timestamp < $1.timestamp }.last
        let lastNursing = appState.nursingLogs.sorted { $0.timestamp < $1.timestamp }.last
        
        var lastTime: Date?
        if let b = lastBottle, let n = lastNursing {
            lastTime = b.timestamp > n.timestamp ? b.timestamp : n.timestamp
        } else {
            lastTime = lastBottle?.timestamp ?? lastNursing?.timestamp
        }
        
        guard let last = lastTime else { return formatInterval(feedIntervalHours) }
        let next = last.addingTimeInterval(feedIntervalHours * 3600)
        let remaining = next.timeIntervalSince(currentTime)
        
        if remaining <= 0 {
            return "Now!"
        }
        
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Baby Status Computed Properties
    
    var babyStatusText: String {
        // 1. Check active sleep timer
        if isSleeping {
            return "Sleeping"
        }
        
        // 2. Check traditional logs (fallback)
        if let lastSleep = appState.sleepLogs.sorted(by: { $0.endTime < $1.endTime }).last {
            // Check if baby is currently sleeping (endTime is in the future)
            if lastSleep.endTime > currentTime {
                return "Sleeping"
            } else {
                return "Awake"
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
    
    // MARK: - Helper Functions
    
    func formatInterval(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)h \(m)m"
        }
    }
    
    var lastFedString: String {
        guard let last = appState.bottleFeedLogs.last else { return "Ready" } // Simplified to bottle
        return last.timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var lastDiaperString: String {
        guard let last = appState.diaperLogs.last else { return "Ready" }
        return last.timestamp.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Subviews

struct StatusCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let mainText: String
    var badgeText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(iconColor)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(mainText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if let badge = badgeText {
                    Text(badge)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(mainText)\(badgeText != nil ? ", \(badgeText!)" : "")")
    }
}

struct ActionCapsule: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact()
            action()
        }) {
            VStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    )
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}
