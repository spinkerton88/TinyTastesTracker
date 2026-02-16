//
//  SleepLogSheet.swift
//  TinyTastesTracker
//
//

import SwiftUI

struct SleepLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
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

    @State private var isSaving = false
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
                        if let start = activeSleepStart {
                            // Wake Up Menu
                            Menu {
                                Text("How was the sleep?")
                                
                                Button {
                                    stopSleep(quality: .excellent)
                                } label: {
                                    Label("Excellent", systemImage: "star.fill")
                                }
                                
                                Button {
                                    stopSleep(quality: .good)
                                } label: {
                                    Label("Good", systemImage: "hand.thumbsup.fill")
                                }
                                
                                Button {
                                    stopSleep(quality: .fair)
                                } label: {
                                    Label("Fair", systemImage: "hand.thumbsdown")
                                }
                                
                                Button {
                                    stopSleep(quality: .poor)
                                } label: {
                                    Label("Poor", systemImage: "exclamationmark.triangle")
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.pink.opacity(0.8))
                                        .frame(width: 200, height: 200)
                                        .shadow(color: .pink.opacity(0.3), radius: 15)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "moon.zzz.fill")
                                            .font(.system(size: 44))
                                        Text("Wake Up")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .accessibilityLabel("Stop Sleep Timer")
                            .accessibilityValue("Running for \(formatDuration(timerDuration))")
                            .accessibilityHint("Double tap to wake up baby and rate sleep")
                        } else {
                            // Start Sleep Button
                            Button {
                                startSleep()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.pink)
                                        .frame(width: 200, height: 200)
                                        .shadow(color: .pink.opacity(0.3), radius: 15)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "moon.stars.fill")
                                            .font(.system(size: 44))
                                        Text("Start Sleep")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .accessibilityLabel("Start Sleep Timer")
                            .accessibilityValue("Not running")
                            .accessibilityHint("Double tap to start tracking sleep")
                        }
                        
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
                            .disabled(isSaving)
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
    
    private func startSleep() {
        HapticManager.impact()
        
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
    
    private func stopSleep(quality: SleepQuality) {
        guard let start = activeSleepStart else { return }
        HapticManager.impact()
        
        let endTime = Date()
        
        Task {
            do {
                try await appState.saveSleepLog(start: start, end: endTime, quality: quality)
                
                await MainActor.run {
                    // Update local state
                    activeSleepStart = nil
                    timerDuration = 0
                    
                    // Stop activity
                    appState.stopSleepActivity()
                    
                    HapticManager.success()
                    errorPresenter.showSuccess("Sleep logged")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorPresenter.present(error)
                }
            }
        }
    }
    
    private func saveManualSleep() {
        Task {
            isSaving = true
            defer { isSaving = false }
            
            do {
                try await appState.saveSleepLog(start: startTime, end: endTime, quality: quality)
                errorPresenter.showSuccess("Sleep logged")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
