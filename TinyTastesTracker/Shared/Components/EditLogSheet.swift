//
//  EditLogSheet.swift
//  TinyTastesTracker
//
//  Generic sheet for editing any log type
//

import SwiftUI

// MARK: - Editable Log Enum

enum EditableLog: Identifiable {
    case nursing(NursingLog)
    case bottle(BottleFeedLog)
    case diaper(DiaperLog)
    case sleep(SleepLog)
    case medication(MedicationLog)
    case pumping(PumpingLog)
    case growth(GrowthMeasurement)
    
    var id: String {
        switch self {
        case .nursing(let log): return log.id ?? UUID().uuidString
        case .bottle(let log): return log.id ?? UUID().uuidString
        case .diaper(let log): return log.id ?? UUID().uuidString
        case .sleep(let log): return log.id ?? UUID().uuidString
        case .medication(let log): return log.id ?? UUID().uuidString
        case .pumping(let log): return log.id ?? UUID().uuidString
        case .growth(let measurement): return measurement.id ?? UUID().uuidString
        }
    }
}

// MARK: - Edit Log Sheet

struct EditLogSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var draftLog: EditableLog
    
    init(log: EditableLog, appState: AppState) {
        self.appState = appState
        _draftLog = State(initialValue: log)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                formContent
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        switch draftLog {
        case .nursing(let log):
            appState.updateNursingLog(log)
        case .bottle(let log):
            appState.updateBottleFeedLog(log)
        case .diaper(let log):
            appState.updateDiaperLog(log)
        case .sleep(let log):
            appState.updateSleepLog(log)
        case .medication(let log):
            appState.updateMedicationLog(log)
        case .pumping(let log):
            appState.updatePumpingLog(log)
        case .growth(let log):
            appState.updateGrowthMeasurement(log)
        }
        HapticManager.success()
    }
    
    @ViewBuilder
    private var formContent: some View {
        switch draftLog {
        case .nursing(let log):
            NursingEditForm(log: Binding(
                get: { log },
                set: { draftLog = .nursing($0) }
            ))
        case .bottle(let log):
            BottleEditForm(log: Binding(
                get: { log },
                set: { draftLog = .bottle($0) }
            ))
        case .diaper(let log):
            DiaperEditForm(log: Binding(
                get: { log },
                set: { draftLog = .diaper($0) }
            ))
        case .sleep(let log):
            SleepEditForm(log: Binding(
                get: { log },
                set: { draftLog = .sleep($0) }
            ))
        case .medication(let log):
            MedicationEditForm(log: Binding(
                get: { log },
                set: { draftLog = .medication($0) }
            ))
        case .pumping(let log):
            PumpingEditForm(log: Binding(
                get: { log },
                set: { draftLog = .pumping($0) }
            ))
        case .growth(let log):
            GrowthEditForm(measurement: Binding(
                get: { log },
                set: { draftLog = .growth($0) }
            ))
        }
    }
}

// MARK: - Nursing Edit Form

struct NursingEditForm: View {
    @Binding var log: NursingLog
    
    var body: some View {
        Section("Details") {
            DatePicker("Time", selection: $log.timestamp)
            
            Picker("Side", selection: $log.side) {
                Text("Left").tag(NursingSide.left)
                Text("Right").tag(NursingSide.right)
            }
            
            HStack {
                Text("Duration")
                Spacer()
                Text(formatDuration(log.duration))
                    .foregroundStyle(.secondary)
            }
            
            DurationPicker(duration: $log.duration)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    }
}

// MARK: - Bottle Edit Form

struct BottleEditForm: View {
    @Binding var log: BottleFeedLog
    
    var body: some View {
        Section("Details") {
            DatePicker("Time", selection: $log.timestamp)
            
            HStack {
                Text("Amount (oz)")
                TextField("Amount", value: $log.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            Picker("Type", selection: $log.feedType) {
                Text("Breast Milk").tag(FeedingType.breastMilk)
                Text("Formula").tag(FeedingType.formula)
                Text("Mixed").tag(FeedingType.mixed)
            }
        }
        
        Section("Notes") {
            TextEditor(text: Binding(
                get: { log.notes ?? "" },
                set: { log.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
        }
    }
}

// MARK: - Diaper Edit Form

struct DiaperEditForm: View {
    @Binding var log: DiaperLog
    
    var body: some View {
        Section("Details") {
            DatePicker("Time", selection: $log.timestamp)
            
            Picker("Type", selection: $log.type) {
                Text("Wet").tag(DiaperType.wet)
                Text("Dirty").tag(DiaperType.dirty)
                Text("Both").tag(DiaperType.both)
            }
        }
    }
}

// MARK: - Sleep Edit Form

struct SleepEditForm: View {
    @Binding var log: SleepLog
    
    var body: some View {
        Section("Time") {
            DatePicker("Start", selection: $log.startTime)
            DatePicker("End", selection: $log.endTime)
            
            HStack {
                Text("Duration")
                Spacer()
                Text(formatDuration(log.duration))
                    .foregroundStyle(.secondary)
            }
        }
        
        Section("Quality") {
            Picker("Sleep Quality", selection: $log.quality) {
                Text("Poor").tag(SleepQuality.poor)
                Text("Fair").tag(SleepQuality.fair)
                Text("Good").tag(SleepQuality.good)
                Text("Excellent").tag(SleepQuality.excellent)
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Medication Edit Form

struct MedicationEditForm: View {
    @Binding var log: MedicationLog
    
    var body: some View {
        Section("Details") {
            DatePicker("Time", selection: $log.timestamp)
            
            TextField("Medicine Name", text: $log.medicineName)
            
            TextField("Dosage", text: $log.dosage)
            
            HStack {
                Text("Baby Weight (lbs)")
                TextField("Weight", value: $log.babyWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
        
        Section("Safety Info") {
            TextEditor(text: Binding(
                get: { log.safetyInfo ?? "" },
                set: { log.safetyInfo = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 60)
        }
        
        Section("Notes") {
            TextEditor(text: Binding(
                get: { log.notes ?? "" },
                set: { log.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 60)
        }
    }
}

// MARK: - Pumping Edit Form

struct PumpingEditForm: View {
    @Binding var log: PumpingLog
    
    var body: some View {
        Section("Details") {
            DatePicker("Time", selection: $log.timestamp)
            
            HStack {
                Text("Left Breast (oz)")
                TextField("Left", value: $log.leftBreastOz, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Right Breast (oz)")
                TextField("Right", value: $log.rightBreastOz, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Total Yield")
                Spacer()
                Text(String(format: "%.1f oz", log.totalYield))
                    .foregroundStyle(.secondary)
            }
        }
        
        Section("Notes") {
            TextEditor(text: Binding(
                get: { log.notes ?? "" },
                set: { log.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
        }
    }
}

// MARK: - Growth Edit Form

struct GrowthEditForm: View {
    @Binding var measurement: GrowthMeasurement
    
    var body: some View {
        Section("Date") {
            DatePicker("Measured On", selection: $measurement.date, displayedComponents: .date)
        }
        
        Section("Measurements") {
            HStack {
                Text("Weight (lbs)")
                TextField("Weight", value: Binding(
                    get: { measurement.weight ?? 0 },
                    set: { measurement.weight = $0 > 0 ? $0 : nil }
                ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Height (in)")
                TextField("Height", value: Binding(
                    get: { measurement.height ?? 0 },
                    set: { measurement.height = $0 > 0 ? $0 : nil }
                ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Head Circumference (in)")
                TextField("Head", value: Binding(
                    get: { measurement.headCircumference ?? 0 },
                    set: { measurement.headCircumference = $0 > 0 ? $0 : nil }
                ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
        }
        
        Section("Notes") {
            TextEditor(text: Binding(
                get: { measurement.notes ?? "" },
                set: { measurement.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 80)
        }
    }
}

// MARK: - Duration Picker Helper

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    @State private var minutes: Int
    @State private var seconds: Int
    
    init(duration: Binding<TimeInterval>) {
        self._duration = duration
        let totalSeconds = Int(duration.wrappedValue)
        self._minutes = State(initialValue: totalSeconds / 60)
        self._seconds = State(initialValue: totalSeconds % 60)
    }
    
    var body: some View {
        HStack {
            minutePicker
            Text("min")
            secondPicker
            Text("sec")
        }
        .onChange(of: minutes) { _, _ in
            updateDuration()
        }
        .onChange(of: seconds) { _, _ in
            updateDuration()
        }
    }
    
    private var minutePicker: some View {
        Picker("Minutes", selection: $minutes) {
            ForEach(0..<60, id: \.self) { minute in
                Text("\(minute)").tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 80)
    }
    
    private var secondPicker: some View {
        Picker("Seconds", selection: $seconds) {
            ForEach(0..<60, id: \.self) { second in
                Text("\(second)").tag(second)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 80)
    }
    
    private func updateDuration() {
        let totalSeconds = (minutes * 60) + seconds
        duration = TimeInterval(totalSeconds)
    }
}
