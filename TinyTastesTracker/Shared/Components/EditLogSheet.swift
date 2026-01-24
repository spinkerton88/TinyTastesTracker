//
//  EditLogSheet.swift
//  TinyTastesTracker
//
//  Generic sheet for editing any log type
//

import SwiftUI
import SwiftData

// MARK: - Editable Log Enum

enum EditableLog: Identifiable {
    case nursing(NursingLog)
    case bottle(BottleFeedLog)
    case diaper(DiaperLog)
    case sleep(SleepLog)
    case medication(MedicationLog)
    case pumping(PumpingLog)
    case growth(GrowthMeasurement)
    
    var id: UUID {
        switch self {
        case .nursing(let log): return log.id
        case .bottle(let log): return log.id
        case .diaper(let log): return log.id
        case .sleep(let log): return log.id
        case .medication(let log): return log.id
        case .pumping(let log): return log.id
        case .growth(let measurement): return measurement.id
        }
    }
}

// MARK: - Edit Log Sheet

struct EditLogSheet: View {
    let log: EditableLog
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
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
        // Changes are automatically saved because we're editing the objects directly
        // SwiftData observes the changes
        try? modelContext.save()
        HapticManager.success()
    }
    
    @ViewBuilder
    private var formContent: some View {
        switch log {
        case .nursing(let nursingLog):
            NursingEditForm(log: nursingLog)
        case .bottle(let bottleLog):
            BottleEditForm(log: bottleLog)
        case .diaper(let diaperLog):
            DiaperEditForm(log: diaperLog)
        case .sleep(let sleepLog):
            SleepEditForm(log: sleepLog)
        case .medication(let medLog):
            MedicationEditForm(log: medLog)
        case .pumping(let pumpLog):
            PumpingEditForm(log: pumpLog)
        case .growth(let measurement):
            GrowthEditForm(measurement: measurement)
        }
    }
}

// MARK: - Nursing Edit Form

struct NursingEditForm: View {
    @Bindable var log: NursingLog
    
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
    @Bindable var log: BottleFeedLog
    
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
    @Bindable var log: DiaperLog
    
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
    @Bindable var log: SleepLog
    
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
    @Bindable var log: MedicationLog
    
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
    @Bindable var log: PumpingLog
    
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
    @Bindable var measurement: GrowthMeasurement
    
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
