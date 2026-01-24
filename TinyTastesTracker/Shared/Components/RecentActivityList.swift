import SwiftUI
import SwiftData

// MARK: - Activity Log Item Model

struct ActivityLogItem: Identifiable {
    let id: UUID
    let timestamp: Date
    let icon: String
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
    @Environment(\.modelContext) private var modelContext

    // Fetch logs directly from database with @Query
    @Query(sort: \NursingLog.timestamp, order: .reverse) private var nursingLogs: [NursingLog]
    @Query(sort: \BottleFeedLog.timestamp, order: .reverse) private var bottleFeedLogs: [BottleFeedLog]
    @Query(sort: \DiaperLog.timestamp, order: .reverse) private var diaperLogs: [DiaperLog]
    @Query(sort: \SleepLog.startTime, order: .reverse) private var sleepLogs: [SleepLog]
    @Query(sort: \MedicationLog.timestamp, order: .reverse) private var medicationLogs: [MedicationLog]
    @Query(sort: \PumpingLog.timestamp, order: .reverse) private var pumpingLogs: [PumpingLog]
    @Query(sort: \MealLog.timestamp, order: .reverse) private var mealLogs: [MealLog]
    @Query(sort: \TriedFoodLog.date, order: .reverse) private var foodLogs: [TriedFoodLog]

    @State private var logToDelete: ActivityLogItem?
    @State private var showingDeleteConfirmation = false
    @State private var logToEdit: EditableLog?
    @State private var showingEditSheet = false


    var recentLogs: [ActivityLogItem] {
        var logs: [ActivityLogItem] = []

        // Nursing logs
        for log in nursingLogs.prefix(5) {
            let minutes = Int(log.duration) / 60
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: "🍼",
                description: "\(log.side.rawValue.capitalized) • \(minutes)m",
                logType: .nursing,
                originalLog: log
            ))
        }
        
        // Bottle feed logs
        for log in bottleFeedLogs.prefix(5) {
            let typeIcon: String
            switch log.feedType {
            case .breastMilk: typeIcon = "🥛"
            case .formula: typeIcon = "🍼"
            case .mixed: typeIcon = "🍶"
            }
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: typeIcon,
                description: "\(String(format: "%.1f", log.amount))oz bottle",
                logType: .bottle,
                originalLog: log
            ))
        }
        
        // Diaper logs
        for log in diaperLogs.prefix(5) {
            let icon = log.type == .wet ? "💧" : (log.type == .dirty ? "💩" : "💧💩")
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: icon,
                description: log.type.rawValue.capitalized,
                logType: .diaper,
                originalLog: log
            ))
        }
        
        // Sleep logs
        for log in sleepLogs.prefix(5) {
            let hours = log.duration / 3600
            let qualityEmoji: String
            switch log.quality {
            case .poor: qualityEmoji = "😴"
            case .fair: qualityEmoji = "😴"
            case .good: qualityEmoji = "😊"
            case .excellent: qualityEmoji = "🌟"
            }
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.startTime,
                icon: qualityEmoji,
                description: String(format: "%.1fh • %@", hours, log.quality.rawValue.capitalized),
                logType: .sleep,
                originalLog: log
            ))
        }
        
        // Medication logs
        for log in medicationLogs.prefix(5) {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayCount = medicationLogs.filter { medLog in
                calendar.isDate(medLog.timestamp, inSameDayAs: today) && medLog.medicineName == log.medicineName
            }.count
            
            let description = "\(log.medicineName) • \(log.dosage)" + (todayCount > 1 ? " (\(todayCount)x today)" : "")
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: "💊",
                description: description,
                logType: .medication,
                originalLog: log
            ))
        }
        
        // Pumping logs
        for log in pumpingLogs.prefix(5) {
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: "🫗",
                description: "Pumped \(String(format: "%.1f", log.totalYield))oz",
                logType: .pumping,
                originalLog: log
            ))
        }

        // Meal logs (Explorer/Toddler) - combine with tried foods
        // First, collect all tried foods grouped by timestamp and meal type
        var triedFoodsByMeal: [String: [TriedFoodLog]] = [:]
        for foodLog in foodLogs {
            let key = "\(foodLog.date.timeIntervalSince1970)_\(foodLog.meal.rawValue)"
            if triedFoodsByMeal[key] == nil {
                triedFoodsByMeal[key] = []
            }
            triedFoodsByMeal[key]?.append(foodLog)
        }
        
        // Track which food logs we've already included in meal logs
        // Meal logs (Explorer/Toddler)
        for log in mealLogs.prefix(10) {
            // Iterate over the foods stored directly on the meal log
            let foodNames = log.foods.compactMap { foodId in
                appState.allKnownFoods.first(where: { $0.id == foodId })?.name
            }
            let foodsText = foodNames.isEmpty ? "None" : foodNames.joined(separator: ", ")
            
            logs.append(ActivityLogItem(
                id: log.id,
                timestamp: log.timestamp,
                icon: "🍽️",
                description: "\(log.mealType.rawValue.capitalized) • \(foodsText)",
                logType: .meal,
                originalLog: log
            ))
        }

        // Tried Food logs that weren't part of a meal
        for log in foodLogs.prefix(10) {
            // Look up the food name from Known Foods (includes custom/recipes)
            let foodName = appState.allKnownFoods.first(where: { $0.id == log.id })?.name ?? log.id

            logs.append(ActivityLogItem(
                id: UUID(), // Wrap purely for List identifiability
                timestamp: log.date,
                icon: "😋",
                description: "Tried \(foodName)",
                logType: .triedFood,
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
            if let log = item.originalLog as? NursingLog {
                return .nursing(log)
            }
        case .bottle:
            if let log = item.originalLog as? BottleFeedLog {
                return .bottle(log)
            }
        case .diaper:
            if let log = item.originalLog as? DiaperLog {
                return .diaper(log)
            }
        case .sleep:
            if let log = item.originalLog as? SleepLog {
                return .sleep(log)
            }
        case .medication:
            if let log = item.originalLog as? MedicationLog {
                return .medication(log)
            }
        case .pumping:
            if let log = item.originalLog as? PumpingLog {
                return .pumping(log)
            }
        case .growth:
            if let measurement = item.originalLog as? GrowthMeasurement {
                return .growth(measurement)
            }
        case .meal, .triedFood:
            // Editing not yet supported from this view for these types
            return nil
        }
        return nil
    }
    
    private func deleteLog(_ item: ActivityLogItem) {
        switch item.logType {
        case .nursing:
            if let log = item.originalLog as? NursingLog {
                appState.deleteNursingLog(log, context: modelContext)
            }
        case .bottle:
            if let log = item.originalLog as? BottleFeedLog {
                appState.deleteBottleFeedLog(log, context: modelContext)
            }
        case .diaper:
            if let log = item.originalLog as? DiaperLog {
                appState.deleteDiaperLog(log, context: modelContext)
            }
        case .sleep:
            if let log = item.originalLog as? SleepLog {
                appState.deleteSleepLog(log, context: modelContext)
            }
        case .medication:
            if let log = item.originalLog as? MedicationLog {
                appState.deleteMedicationLog(log, context: modelContext)
            }
        case .pumping:
            if let log = item.originalLog as? PumpingLog {
                appState.deletePumpingLog(log, context: modelContext)
            }
        case .growth:
            if let measurement = item.originalLog as? GrowthMeasurement {
                appState.deleteGrowthMeasurement(measurement, context: modelContext)
            }
        case .meal:
            if let log = item.originalLog as? MealLog {
                appState.deleteMealLog(log, context: modelContext)
            }
        case .triedFood:
            if let log = item.originalLog as? TriedFoodLog {
                appState.deleteFoodLog(log, context: modelContext)
            }
        }
        
        HapticManager.success()
    }
}
