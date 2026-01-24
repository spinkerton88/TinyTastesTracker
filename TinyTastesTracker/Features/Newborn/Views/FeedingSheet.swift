import SwiftUI
import SwiftData

struct FeedingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    
    @State private var selectedMode: Int = 0 // 0 = Nursing, 1 = Bottle, 2 = Pumping
    @State private var nursingSubMode: Int = 0 // 0 = Timer, 1 = Manual
    
    // Nursing State (Timer)
    @State private var leftTimerStart: Date?
    @State private var rightTimerStart: Date?
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Nursing State (Manual)
    @State private var manualDate: Date = Date()
    @State private var leftDurationMinutes: Int = 0
    @State private var rightDurationMinutes: Int = 0
    
    // Bottle State
    @State private var amount: Double = 4.0
    @State private var feedType: FeedingType = .formula
    @State private var notes: String = ""
    @State private var customAmount: String = ""
    @State private var useCustomAmount = false
    let presetAmounts: [Double] = [2, 3, 4, 5, 6, 7, 8]
    
    // Pumping State
    @State private var leftBreastOz: Double = 0.0
    @State private var rightBreastOz: Double = 0.0
    @State private var pumpingNotes: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Selector
                Picker("Feeding Mode", selection: $selectedMode) {
                    Text("Nursing").tag(0)
                    Text("Bottle").tag(1)
                    Text("Pumping").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedMode == 0 {
                    // MARK: - Nursing View
                    VStack(spacing: 0) {
                        // Sub-mode Picker
                        Picker("Nursing Mode", selection: $nursingSubMode) {
                            Text("Timer").tag(0)
                            Text("Manual").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        if nursingSubMode == 0 {
                            // Timer Mode
                            ScrollView {
                                VStack(spacing: 24) {
                                    Text("Nursing Timers")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 16) {
                                        NursingTimerCard(
                                            side: .left,
                                            startTime: leftTimerStart,
                                            currentTime: currentTime,
                                            themeColor: appState.themeColor,
                                            onStart: {
                                                HapticManager.impact()
                                                leftTimerStart = Date()
                                            },
                                            onStop: {
                                                if let start = leftTimerStart {
                                                    let duration = Date().timeIntervalSince(start)
                                                    appState.saveNursingLog(startTime: start, duration: duration, side: .left, context: modelContext)
                                                    leftTimerStart = nil
                                                    HapticManager.success()
                                                }
                                            }
                                        )
                                        
                                        NursingTimerCard(
                                            side: .right,
                                            startTime: rightTimerStart,
                                            currentTime: currentTime,
                                            themeColor: appState.themeColor,
                                            onStart: {
                                                HapticManager.impact()
                                                rightTimerStart = Date()
                                            },
                                            onStop: {
                                                if let start = rightTimerStart {
                                                    let duration = Date().timeIntervalSince(start)
                                                    appState.saveNursingLog(startTime: start, duration: duration, side: .right, context: modelContext)
                                                    rightTimerStart = nil
                                                    HapticManager.success()
                                                }
                                            }
                                        )
                                    }
                                    
                                    // Summary of Recent Nursing
                                    if !appState.nursingLogs.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Recent Nursing")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            ForEach(appState.nursingLogs.suffix(3).reversed(), id: \.id) { log in
                                                HStack {
                                                    Text(log.side.rawValue.capitalized)
                                                    Spacer()
                                                    Text("\(Int(log.duration / 60))m")
                                                    Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(.vertical, 4)
                                                .font(.caption)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding()
                            }
                        } else {
                            // Manual Entry Mode
                            Form {
                                Section("Date & Time") {
                                    DatePicker("When", selection: $manualDate, displayedComponents: [.date, .hourAndMinute])
                                }
                                
                                Section("Duration") {
                                    Stepper("Left: \(leftDurationMinutes) min", value: $leftDurationMinutes, in: 0...60)
                                    Stepper("Right: \(rightDurationMinutes) min", value: $rightDurationMinutes, in: 0...60)
                                }
                                
                                Section {
                                    Button("Save Manual Entry") {
                                        saveManualNursing()
                                    }
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.white)
                                    .listRowBackground(appState.themeColor)
                                    .disabled(leftDurationMinutes == 0 && rightDurationMinutes == 0)
                                }
                            }
                        }
                    }
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
                    
                } else if selectedMode == 2 {
                    // MARK: - Pumping View
                    Form {
                        Section("Pumping Session") {
                            HStack {
                                Text("Left Breast")
                                Spacer()
                                Stepper("\(String(format: "%.1f", leftBreastOz)) oz", value: $leftBreastOz, in: 0...20, step: 0.5)
                            }
                            
                            HStack {
                                Text("Right Breast")
                                Spacer()
                                Stepper("\(String(format: "%.1f", rightBreastOz)) oz", value: $rightBreastOz, in: 0...20, step: 0.5)
                            }
                            
                            HStack {
                                Text("Total Yield")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(String(format: "%.1f", leftBreastOz + rightBreastOz)) oz")
                                    .fontWeight(.bold)
                                    .foregroundStyle(appState.themeColor)
                            }
                        }
                        
                        Section("Notes (Optional)") {
                            TextField("Add any observations...", text: $pumpingNotes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section {
                            Button("Save Pumping Session") {
                                savePumping()
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .listRowBackground(appState.themeColor)
                            .disabled(leftBreastOz == 0 && rightBreastOz == 0)
                        }
                    }
                    
                } else {
                    // MARK: - Bottle View
                    Form {
                        Section("Amount (oz)") {
                            if !useCustomAmount {
                                Picker("Amount", selection: $amount) {
                                    ForEach(presetAmounts, id: \.self) { amt in
                                        Text("\(Int(amt)) oz").tag(amt)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                Button {
                                    useCustomAmount = true
                                    customAmount = String(format: "%.1f", amount)
                                } label: {
                                    Text("Enter custom amount")
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                HStack {
                                    TextField("Amount", text: $customAmount)
                                        .keyboardType(.decimalPad)
                                    Text("oz")
                                }
                                
                                Button {
                                    useCustomAmount = false
                                } label: {
                                    Text("Use preset amounts")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        
                        Section("Type") {
                            Picker("Feed Type", selection: $feedType) {
                                Text("Breast Milk").tag(FeedingType.breastMilk)
                                Text("Formula").tag(FeedingType.formula)
                                Text("Mixed").tag(FeedingType.mixed)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Section("Notes (Optional)") {
                            TextField("Add any observations...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section {
                            Button("Save Bottle Feed") {
                                saveBottleFeed()
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .listRowBackground(appState.themeColor)
                        }
                    }
                }
            }
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .withSage(context: "User is logging a feeding. Mode: \(selectedMode == 0 ? "Nursing" : selectedMode == 1 ? "Bottle feeding" : "Pumping").", appState: appState)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveBottleFeed() {
        let finalAmount = useCustomAmount ? (Double(customAmount) ?? amount) : amount
        appState.saveBottleFeedLog(
            amount: finalAmount,
            feedType: feedType,
            notes: notes.isEmpty ? nil : notes,
            context: modelContext
        )
        HapticManager.success()
        dismiss()
    }
    
    private func saveManualNursing() {
        // Save left side if duration > 0
        if leftDurationMinutes > 0 {
            let duration = TimeInterval(leftDurationMinutes * 60)
            appState.saveNursingLog(startTime: manualDate, duration: duration, side: .left, context: modelContext)
        }
        
        // Save right side if duration > 0
        if rightDurationMinutes > 0 {
            let duration = TimeInterval(rightDurationMinutes * 60)
            appState.saveNursingLog(startTime: manualDate, duration: duration, side: .right, context: modelContext)
        }
        
        HapticManager.success()
        
        // Reset manual entry fields
        leftDurationMinutes = 0
        rightDurationMinutes = 0
        manualDate = Date()
        
        dismiss()
    }
    
    private func savePumping() {
        appState.savePumpingLog(
            leftBreastOz: leftBreastOz,
            rightBreastOz: rightBreastOz,
            notes: pumpingNotes.isEmpty ? nil : pumpingNotes,
            context: modelContext
        )
        HapticManager.success()
        dismiss()
    }
}
