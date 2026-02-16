//
//  RecentActivityList.swift
//  TinyTastesTracker
//
//

import SwiftUI

// MARK: - Activity Log Item Model

struct ActivityLogItem: Identifiable {
    let id: String // Changed to String to match Firestore IDs usually, but could be UUID if model uses it. Firestore models use String?.
    // Previous code used UUID. Models like NursingLog now conform to Identifiable with String? id.
    // I should check if I can just use String. Or fallback to UUID string.
    let timestamp: Date
    let icon: String // Emoji
    let description: String
    let logType: LogType
    let originalLog: Any  // Reference to the actual log object
    
    enum LogType {
        case nursing, bottle, diaper, sleep, medication, pumping, growth, meal, triedFood
    }
}

// MARK: - Recent Activity List

struct RecentActivityList: View {
    @Bindable var appState: AppState

    @State private var logToDelete: ActivityLogItem?
    @State private var showingDeleteConfirmation = false
    @State private var logToEdit: EditableLog?
    @State private var showingEditSheet = false

    var recentLogs: [ActivityLogItem] {
        var logs: [ActivityLogItem] = []

        // Nursing logs
        for log in appState.nursingLogs.prefix(5) {
            let minutes = Int(log.duration) / 60
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: "🍼",
                description: "\(log.side.rawValue.capitalized) • \(minutes)m",
                logType: .nursing,
                originalLog: log
            ))
        }
        
        // Bottle feed logs
        for log in appState.bottleFeedLogs.prefix(5) {
            let typeIcon: String
            switch log.feedType {
            case .breastMilk: typeIcon = "🥛"
            case .formula: typeIcon = "🍼"
            case .mixed: typeIcon = "🍶"
            }
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: typeIcon,
                description: "\(String(format: "%.1f", log.amount))oz bottle",
                logType: .bottle,
                originalLog: log
            ))
        }
        
        // Diaper logs
        for log in appState.diaperLogs.prefix(5) {
            let icon = log.type == .wet ? "💧" : (log.type == .dirty ? "💩" : "💧💩")
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: icon,
                description: log.type.rawValue.capitalized,
                logType: .diaper,
                originalLog: log
            ))
        }
        
        // Sleep logs
        for log in appState.sleepLogs.prefix(5) {
            let hours = log.duration / 3600
            let qualityEmoji: String
            switch log.quality {
            case .poor: qualityEmoji = "😴"
            case .fair: qualityEmoji = "😴"
            case .good: qualityEmoji = "😊"
            case .excellent: qualityEmoji = "🌟"
            }
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.startTime,
                icon: qualityEmoji,
                description: String(format: "%.1fh • %@", hours, log.quality.rawValue.capitalized),
                logType: .sleep,
                originalLog: log
            ))
        }
        
        // Medication logs
        let medLogs = appState.medicationLogs
        for log in medLogs.prefix(5) {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayCount = medLogs.filter { medLog in
                calendar.isDate(medLog.timestamp, inSameDayAs: today) && medLog.medicineName == log.medicineName
            }.count
            
            let description = "\(log.medicineName) • \(log.dosage)" + (todayCount > 1 ? " (\(todayCount)x today)" : "")
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: "💊",
                description: description,
                logType: .medication,
                originalLog: log
            ))
        }
        
        // Pumping logs
        for log in appState.pumpingLogs.prefix(5) {
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: "🫗",
                description: "Pumped \(String(format: "%.1f", log.totalYield))oz",
                logType: .pumping,
                originalLog: log
            ))
        }

        // Meal logs (Explorer/Toddler)
        for log in appState.mealLogs.prefix(10) {
            let foodNames = log.foods.compactMap { foodId in
                appState.allKnownFoods.first(where: { $0.id == foodId })?.name
            }
            let foodsText = foodNames.isEmpty ? "None" : foodNames.joined(separator: ", ")
            
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.timestamp,
                icon: "🍽️",
                description: "\(log.mealType.rawValue.capitalized) • \(foodsText)",
                logType: .meal,
                originalLog: log
            ))
        }

        // Tried Food logs that weren't part of a meal
        for log in appState.foodLogs.prefix(20) { // Increase prefix to ensure we find enough standalone logs
            // Check if this food log is part of a meal log
            let isPartOfMeal = appState.mealLogs.contains { mealLog in
                // Check if timestamps match (created at same time) and food is in the meal
                abs(mealLog.timestamp.timeIntervalSince(log.date)) < 1.0 && mealLog.foods.contains(log.foodId)
            }
            
            if isPartOfMeal { continue }
            
            let foodName = appState.allKnownFoods.first(where: { $0.id == log.foodName })?.name ?? log.foodName

            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.date,
                icon: "😋",
                description: "Tried \(foodName)",
                logType: .triedFood,
                originalLog: log
            ))
        }
        
        // Growth logs
        for log in appState.growthMeasurements.prefix(5) {
            var details: [String] = []
            if let weight = log.weight { details.append("\(String(format: "%.1f", weight))lb") }
            if let height = log.height { details.append("\(String(format: "%.1f", height))in") }
            if let head = log.headCircumference { details.append("Head: \(String(format: "%.1f", head))in") }
            
            let description = details.joined(separator: ", ")
            
            logs.append(ActivityLogItem(
                id: log.id ?? UUID().uuidString,
                timestamp: log.date,
                icon: "📏",
                description: description.isEmpty ? "Growth Log" : description,
                logType: .growth,
                originalLog: log
            ))
        }
        
        return logs.sorted { $0.timestamp > $1.timestamp }.prefix(10).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if recentLogs.isEmpty {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView(
                        "No Activity Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Log your first feed, sleep, or diaper change above to start tracking.")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Activity Yet")
                            .font(.headline)
                        Text("Log your first feed, sleep, or diaper change above to start tracking.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
                    .padding(.horizontal)
                }
            } else {
                ForEach(recentLogs) { item in
                    HStack {
                        Text(item.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.description)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            logToDelete = item
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            logToEdit = createEditableLog(from: item)
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this log?",
            isPresented: $showingDeleteConfirmation,
            presenting: logToDelete
        ) { item in
            Button("Delete", role: .destructive) {
                deleteLog(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("This action cannot be undone.")
        }
        .sheet(item: $logToEdit) { log in
            EditLogSheet(log: log, appState: appState)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createEditableLog(from item: ActivityLogItem) -> EditableLog? {
        switch item.logType {
        case .nursing:
            if let log = item.originalLog as? NursingLog { return .nursing(log) }
        case .bottle:
            if let log = item.originalLog as? BottleFeedLog { return .bottle(log) }
        case .diaper:
            if let log = item.originalLog as? DiaperLog { return .diaper(log) }
        case .sleep:
            if let log = item.originalLog as? SleepLog { return .sleep(log) }
        case .medication:
            if let log = item.originalLog as? MedicationLog { return .medication(log) }
        case .pumping:
            if let log = item.originalLog as? PumpingLog { return .pumping(log) }
        case .growth:
            if let measurement = item.originalLog as? GrowthMeasurement { return .growth(measurement) }
        case .meal, .triedFood:
            return nil
        }
        return nil
    }
    
    private func deleteLog(_ item: ActivityLogItem) {
        switch item.logType {
        case .nursing:
            if let log = item.originalLog as? NursingLog { appState.deleteNursingLog(log) }
        case .bottle:
            if let log = item.originalLog as? BottleFeedLog { appState.deleteBottleFeedLog(log) }
        case .diaper:
            if let log = item.originalLog as? DiaperLog { appState.deleteDiaperLog(log) }
        case .sleep:
            if let log = item.originalLog as? SleepLog { appState.deleteSleepLog(log) }
        case .medication:
            if let log = item.originalLog as? MedicationLog { appState.deleteMedicationLog(log) }
        case .pumping:
            if let log = item.originalLog as? PumpingLog { appState.deletePumpingLog(log) }
        case .growth:
            if let measurement = item.originalLog as? GrowthMeasurement { appState.deleteGrowthMeasurement(measurement) }
        case .meal:
            if let log = item.originalLog as? MealLog { appState.deleteMealLog(log) }
        case .triedFood:
            if let log = item.originalLog as? TriedFoodLog { appState.deleteFoodLog(log) }
        }
        
        HapticManager.success()
    }
}
