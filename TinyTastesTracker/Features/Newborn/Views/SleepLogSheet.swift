import SwiftUI
import SwiftData

struct SleepLogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var appState: AppState
    
    // Modes: 0 = Timer, 1 = Manual
    @State private var selectedMode = 0
    
    // Manual Entry State
    @State private var startTime = Date().addingTimeInterval(-3600)
    @State private var endTime = Date()
    @State private var quality: SleepQuality = .good
    
    // Timer State
    @State private var activeSleepStart: Date?
    @State private var timerDuration: TimeInterval = 0
    @State private var showingQualityPicker = false
    @State private var pendingSleepStart: Date?
    @State private var pendingSleepEnd: Date?
    @State private var selectedQuality: SleepQuality = .good
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedMode) {
                    Text("Timer").tag(0)
                    Text("Manual").tag(1)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Logging Mode")
                .accessibilityHint("Select Timer to track sleep now, or Manual to log past sleep")
                .padding()
                
                if selectedMode == 0 {
                    // MARK: - Timer Mode
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Time Display
                        VStack(spacing: 8) {
                            Text(activeSleepStart != nil ? "Baby is Sleeping" : "Baby is Awake")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text(formatDuration(timerDuration))
                                .font(.system(size: 60, weight: .light, design: .monospaced))
                                .contentTransition(.numericText())
                        }
                        
                        // Action Button
                        Button {
                            toggleSleepTimer()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(activeSleepStart != nil ? Color.pink.opacity(0.8) : Color.pink)
                                    .frame(width: 200, height: 200)
                                    .shadow(color: .pink.opacity(0.3), radius: 15)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: activeSleepStart != nil ? "moon.zzz.fill" : "moon.stars.fill")
                                        .font(.system(size: 44))
                                    Text(activeSleepStart != nil ? "Wake Up" : "Start Sleep")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel(activeSleepStart != nil ? "Stop Sleep Timer" : "Start Sleep Timer")
                        .accessibilityValue(activeSleepStart != nil ? "Running for \(formatDuration(timerDuration))" : "Not running")
                        .accessibilityHint(activeSleepStart != nil ? "Double tap to wake up baby" : "Double tap to start tracking sleep")
                        
                        if let start = activeSleepStart {
                            Text("Started at \(start.formatted(date: .omitted, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // MARK: - Manual Mode
                    Form {
                        Section("Sleep Duration") {
                            DatePicker("Start", selection: $startTime)
                                .accessibilityLabel("Sleep Start Time")
                            DatePicker("End", selection: $endTime)
                                .accessibilityLabel("Sleep End Time")
                        }
                        
                        Section("Quality") {
                            Picker("Sleep Quality", selection: $quality) {
                                Text("Poor").tag(SleepQuality.poor)
                                Text("Fair").tag(SleepQuality.fair)
                                Text("Good").tag(SleepQuality.good)
                                Text("Excellent").tag(SleepQuality.excellent)
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Sleep Quality Rating")
                        }
                        
                        Section {
                            Button("Save Sleep Log") {
                                saveManualSleep()
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .listRowBackground(appState.themeColor)
                        }
                    }
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                checkActiveSleep()
            }
            .onReceive(timer) { _ in
                if let start = activeSleepStart {
                    timerDuration = Date().timeIntervalSince(start)
                } else {
                    timerDuration = 0
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkActiveSleep()
                }
            }
            .confirmationDialog("How was the sleep?", isPresented: $showingQualityPicker) {
                Button("😴 Excellent") {
                    selectedQuality = .excellent
                    saveSleepWithQuality()
                }
                Button("😊 Good") {
                    selectedQuality = .good
                    saveSleepWithQuality()
                }
                Button("😐 Fair") {
                    selectedQuality = .fair
                    saveSleepWithQuality()
                }
                Button("😟 Poor") {
                    selectedQuality = .poor
                    saveSleepWithQuality()
                }
                Button("Cancel", role: .cancel) {
                    // Don't save, just dismiss
                    pendingSleepEnd = nil
                }
            } message: {
                Text("Rate the sleep quality")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkActiveSleep() {
        if let start = WidgetDataManager.activeSleepStartTime() {
            activeSleepStart = start
            timerDuration = Date().timeIntervalSince(start)
        } else {
            activeSleepStart = nil
            timerDuration = 0
        }
    }
    
    private func toggleSleepTimer() {
        HapticManager.impact()
        
        if let start = activeSleepStart {
            // Stop Sleep (Wake Up) - Show quality picker
            pendingSleepStart = start
            pendingSleepEnd = Date()
            selectedQuality = .good // Default selection
            showingQualityPicker = true
            
            // Update local state immediately
            activeSleepStart = nil
            timerDuration = 0
            
            // Stop activity
            appState.stopSleepActivity()
        } else {
            // Start Sleep
            let startTime = Date()
            
            // Update local state immediately BEFORE calling the activity
            activeSleepStart = startTime
            timerDuration = 0
            
            // Start the activity
            appState.startSleepActivity()
            
            HapticManager.success()
            
            // Dismiss sheet so user can see dashboard status
            dismiss()
        }
    }
    
    private func saveSleepWithQuality() {
        guard let start = pendingSleepStart, let end = pendingSleepEnd else { return }
        
        // Save log with selected quality
        appState.saveSleepLog(start: start, end: end, quality: selectedQuality, context: modelContext)
        
        HapticManager.success()
        
        // Clear pending state
        pendingSleepStart = nil
        pendingSleepEnd = nil
        
        // Dismiss sheet
        dismiss()
    }
    
    private func saveManualSleep() {
        appState.saveSleepLog(start: startTime, end: endTime, quality: quality, context: modelContext)
        HapticManager.success()
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
