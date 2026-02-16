//
//  NewbornManager.swift
//  TinyTastesTracker
//
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAnalytics
import ActivityKit
import WidgetKit

@Observable
class NewbornManager {
    // Data Arrays (Updated via Firestore Listeners)
    var nursingLogs: [NursingLog] = []
    var sleepLogs: [SleepLog] = []
    var diaperLogs: [DiaperLog] = []
    var bottleFeedLogs: [BottleFeedLog] = []
    var pumpingLogs: [PumpingLog] = []
    var medicationLogs: [MedicationLog] = []
    var growthMeasurements: [GrowthMeasurement] = []
    var savedMedications: [SavedMedication] = []

    // Dependencies
    private let notificationManager: NotificationManager
    private let errorPresenter: ErrorPresenter

    // Firestore Services
    private let nursingService = FirestoreService<NursingLog>(collectionName: "nursing_logs")
    private let sleepService = FirestoreService<SleepLog>(collectionName: "sleep_logs")
    private let diaperService = FirestoreService<DiaperLog>(collectionName: "diaper_logs")
    private let bottleService = FirestoreService<BottleFeedLog>(collectionName: "bottle_feed_logs")
    private let pumpingService = FirestoreService<PumpingLog>(collectionName: "pumping_logs")
    private let medsService = FirestoreService<MedicationLog>(collectionName: "medication_logs")
    private let growthService = FirestoreService<GrowthMeasurement>(collectionName: "growth_measurements")
    private let savedMedsService = FirestoreService<SavedMedication>(collectionName: "saved_medications")

    // Listener Registrations
    private var listeners: [ListenerRegistration] = []

    // MARK: - Initialization

    init(notificationManager: NotificationManager, errorPresenter: ErrorPresenter) {
        self.notificationManager = notificationManager
        self.errorPresenter = errorPresenter
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    // MARK: - Save Methods

    func saveNursingLog(startTime: Date, duration: TimeInterval, side: NursingSide, ownerId: String, babyId: String) async throws {
        // Generate ID locally
        let newId = UUID().uuidString
        let log = NursingLog(id: newId, ownerId: ownerId, babyId: babyId, timestamp: startTime, duration: duration, side: side)
        
        // Optimistic Update
        self.nursingLogs.append(log)
        self.nursingLogs.sort { $0.timestamp > $1.timestamp }
        
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            // Queue for later sync
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .nursingLog,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            // Return success for optimistic UI
            return
        }
        
        // Attempt save with retry logic
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.nursingService.add(log, withId: newId)
                }
            }

            // Track analytics event
            Analytics.logEvent("nursing_log_created", parameters: [
                "duration_minutes": Int(duration / 60),
                "side": side.rawValue
            ])
        } catch {
            // Rollback on failure
            if let index = self.nursingLogs.firstIndex(where: { $0.id == newId }) {
                self.nursingLogs.remove(at: index)
            }
            throw error
        }
        
        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .nursing, time: startTime)
        
        // Schedule feed reminder (fire and forget)
        Task {
            await scheduleFeedReminderIfEnabled(childName: "Baby")
        }
    }

    func saveSleepLog(start: Date, end: Date, quality: SleepQuality, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let log = SleepLog(id: newId, ownerId: ownerId, babyId: babyId, startTime: start, endTime: end, quality: quality)
        
        // Optimistic Update
        self.sleepLogs.append(log)
        self.sleepLogs.sort { $0.startTime > $1.startTime }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .sleepLog,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.sleepService.add(log, withId: newId)
                }
            }

            // Track analytics event
            let durationHours = (end.timeIntervalSince(start)) / 3600
            Analytics.logEvent("sleep_log_created", parameters: [
                "duration_hours": Int(durationHours),
                "quality": quality.rawValue
            ])
        } catch {
            if let index = self.sleepLogs.firstIndex(where: { $0.id == newId }) {
                self.sleepLogs.remove(at: index)
            }
            throw error
        }
        
        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .sleep, time: end)
    }

    func saveDiaperLog(type: DiaperType, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let log = DiaperLog(id: newId, ownerId: ownerId, babyId: babyId, timestamp: Date(), type: type)
        
        // Optimistic Update
        self.diaperLogs.append(log)
        self.diaperLogs.sort { $0.timestamp > $1.timestamp }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .diaperLog,
                    payload: encoded,
                    priority: .normal
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.diaperService.add(log, withId: newId)
                }
            }
        } catch {
            if let index = self.diaperLogs.firstIndex(where: { $0.id == newId }) {
                self.diaperLogs.remove(at: index)
            }
            throw error
        }
        
        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .diaper, time: log.timestamp)
    }

    func saveBottleFeedLog(amount: Double, feedType: FeedingType, notes: String? = nil, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let log = BottleFeedLog(id: newId, ownerId: ownerId, babyId: babyId, timestamp: Date(), amount: amount, feedType: feedType, notes: notes)
        
        // Optimistic Update
        self.bottleFeedLogs.append(log)
        self.bottleFeedLogs.sort { $0.timestamp > $1.timestamp }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .bottleFeedLog,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.bottleService.add(log, withId: newId)
                }
            }
        } catch {
            if let index = self.bottleFeedLogs.firstIndex(where: { $0.id == newId }) {
                self.bottleFeedLogs.remove(at: index)
            }
            throw error
        }
        
        // Update Widgets
        updateWidgetData(lastFeed: log.timestamp, type: feedType.rawValue)
        WidgetDataManager.saveLastLogTime(type: .bottle, time: log.timestamp)
        
        Task {
            await scheduleFeedReminderIfEnabled(childName: "Baby")
        }
    }
    
    func savePumpingLog(leftBreastOz: Double, rightBreastOz: Double, notes: String? = nil, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let log = PumpingLog(id: newId, ownerId: ownerId, babyId: babyId, timestamp: Date(), leftBreastOz: leftBreastOz, rightBreastOz: rightBreastOz, notes: notes)
        
        // Optimistic Update
        self.pumpingLogs.append(log)
        self.pumpingLogs.sort { $0.timestamp > $1.timestamp }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .pumpingLog,
                    payload: encoded,
                    priority: .normal
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.pumpingService.add(log, withId: newId)
                }
            }
        } catch {
            if let index = self.pumpingLogs.firstIndex(where: { $0.id == newId }) {
                self.pumpingLogs.remove(at: index)
            }
            throw error
        }
        
        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .bottle, time: log.timestamp)
    }
    
    func saveMedicationLog(medicineName: String, babyWeight: Double, dosage: String, safetyInfo: String? = nil, notes: String? = nil, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let log = MedicationLog(id: newId, ownerId: ownerId, babyId: babyId, timestamp: Date(), medicineName: medicineName, babyWeight: babyWeight, dosage: dosage, safetyInfo: safetyInfo, notes: notes)
        
        // Optimistic Update
        self.medicationLogs.append(log)
        self.medicationLogs.sort { $0.timestamp > $1.timestamp }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(log) {
                let operation = QueuedOperation(
                    type: .medicationLog,
                    payload: encoded,
                    priority: .critical
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.medsService.add(log, withId: newId)
                }
            }
        } catch {
            if let index = self.medicationLogs.firstIndex(where: { $0.id == newId }) {
                self.medicationLogs.remove(at: index)
            }
            throw error
        }
    }

    func saveGrowthMeasurement(weight: Double?, height: Double?, headCircumference: Double?, notes: String? = nil, ownerId: String, babyId: String) async throws {
        let newId = UUID().uuidString
        let measurement = GrowthMeasurement(id: newId, ownerId: ownerId, babyId: babyId, date: Date(), weight: weight, height: height, headCircumference: headCircumference, notes: notes)
        
        // Optimistic Update
        self.growthMeasurements.append(measurement)
        self.growthMeasurements.sort { $0.date > $1.date }
        
        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(measurement) {
                let operation = QueuedOperation(
                    type: .growthMeasurement,
                    payload: encoded,
                    priority: .high
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }
        
        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.growthService.add(measurement, withId: newId)
                }
            }
        } catch {
            if let index = self.growthMeasurements.firstIndex(where: { $0.id == newId }) {
                self.growthMeasurements.remove(at: index)
            }
            throw error
        }
    }

    // MARK: - Update Methods
    
    func updateNursingLog(_ log: NursingLog) {
        Task {
            do {
                try await nursingService.update(log)
            } catch {
                print("Error updating nursing log: \(error)")
            }
        }
    }
    
    func updateSleepLog(_ log: SleepLog) {
        Task {
            do {
                try await sleepService.update(log)
            } catch {
                print("Error updating sleep log: \(error)")
            }
        }
    }
    
    func updateDiaperLog(_ log: DiaperLog) {
        Task {
            do {
                try await diaperService.update(log)
            } catch {
                print("Error updating diaper log: \(error)")
            }
        }
    }
    
    func updateBottleFeedLog(_ log: BottleFeedLog) {
        Task {
            do {
                try await bottleService.update(log)
            } catch {
                print("Error updating bottle log: \(error)")
            }
        }
    }
    
    func updatePumpingLog(_ log: PumpingLog) {
        Task {
            do {
                try await pumpingService.update(log)
            } catch {
                print("Error updating pumping log: \(error)")
            }
        }
    }
    
    func updateMedicationLog(_ log: MedicationLog) {
        Task {
            do {
                try await medsService.update(log)
            } catch {
                print("Error updating medication log: \(error)")
            }
        }
    }
    
    func updateGrowthMeasurement(_ measurement: GrowthMeasurement) {
        Task {
            do {
                try await growthService.update(measurement)
            } catch {
                print("Error updating growth measurement: \(error)")
            }
        }
    }

    // MARK: - Delete Methods
    
    func deleteNursingLog(_ log: NursingLog) {
        guard let id = log.id else { return }
        Task { try? await nursingService.delete(id: id) }
    }
    
    func deleteSleepLog(_ log: SleepLog) {
        guard let id = log.id else { return }
        Task { try? await sleepService.delete(id: id) }
    }
    
    func deleteDiaperLog(_ log: DiaperLog) {
        guard let id = log.id else { return }
        Task { try? await diaperService.delete(id: id) }
    }
    
    func deleteBottleFeedLog(_ log: BottleFeedLog) {
        guard let id = log.id else { return }
        Task { try? await bottleService.delete(id: id) }
    }
    
    func deletePumpingLog(_ log: PumpingLog) {
        guard let id = log.id else { return }
        Task { try? await pumpingService.delete(id: id) }
    }
    
    func deleteMedicationLog(_ log: MedicationLog) {
        guard let id = log.id else { return }
        Task { try? await medsService.delete(id: id) }
    }
    
    func deleteGrowthMeasurement(_ measurement: GrowthMeasurement) {
        guard let id = measurement.id else { return }
        Task { try? await growthService.delete(id: id) }
    }

    // MARK: - Statistics

    var last24HourStats: (feedingCount: Int, diaperCount: Int, totalSleepHours: Double) {
        let last24Hours = Date().addingTimeInterval(-24 * 3600)

        let nursingCount = nursingLogs.filter { $0.timestamp >= last24Hours }.count
        let bottleCount = bottleFeedLogs.filter { $0.timestamp >= last24Hours }.count
        let feedingCount = nursingCount + bottleCount

        let diaperCount = diaperLogs.filter { $0.timestamp >= last24Hours }.count

        let recentSleepLogs = sleepLogs.filter { $0.startTime >= last24Hours }
        let totalSleepHours = recentSleepLogs.reduce(0.0) { $0 + $1.duration / 3600.0 }

        return (feedingCount, diaperCount, totalSleepHours)
    }
    
    var todayStats: (wetDiapers: Int, dirtyDiapers: Int, feedingCount: Int, sleepHours: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let wet = diaperLogs.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today) && ($0.type == .wet || $0.type == .both)
        }.count
        
        let dirty = diaperLogs.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today) && ($0.type == .dirty || $0.type == .both)
        }.count
        
        let nursing = nursingLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
        let bottle = bottleFeedLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
        let feedingCount = nursing + bottle
        
        let todaySleep = sleepLogs.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
        let sleepHours = todaySleep.reduce(0.0) { $0 + $1.duration } / 3600.0
        
        return (wet, dirty, feedingCount, sleepHours)
    }

    // MARK: - Chart Data

    func getDailyFeedingData(days: Int = 7) -> [DailyFeedingData] {
        let calendar = Calendar.current
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)

        // Group feedings by day
        var dataByDate: [Date: (nursing: Int, bottle: Int)] = [:]

        for log in nursingLogs.filter({ $0.timestamp >= cutoffDate }) {
            let dayStart = calendar.startOfDay(for: log.timestamp)
            dataByDate[dayStart, default: (0, 0)].nursing += 1
        }

        for log in bottleFeedLogs.filter({ $0.timestamp >= cutoffDate }) {
            let dayStart = calendar.startOfDay(for: log.timestamp)
            dataByDate[dayStart, default: (0, 0)].bottle += 1
        }

        return dataByDate.map { date, counts in
            DailyFeedingData(date: date, nursingCount: counts.nursing, bottleCount: counts.bottle)
        }.sorted { $0.date < $1.date }
    }

    func getWeeklySleepData() -> [DailySleepData] {
        let calendar = Calendar.current
        let last7Days = Date().addingTimeInterval(-7 * 24 * 3600)

        // Group sleep logs by day
        var dataByDate: [Date: (hours: Double, count: Int, qualitySum: Double)] = [:]

        for log in sleepLogs.filter({ $0.startTime >= last7Days }) {
            let dayStart = calendar.startOfDay(for: log.startTime)
            let hours = log.duration / 3600.0
            let qualityValue = qualityToDouble(log.quality)

            if var existing = dataByDate[dayStart] {
                existing.hours += hours
                existing.count += 1
                existing.qualitySum += qualityValue
                dataByDate[dayStart] = existing
            } else {
                dataByDate[dayStart] = (hours, 1, qualityValue)
            }
        }

        return dataByDate.map { date, data in
            DailySleepData(
                date: date,
                totalHours: data.hours,
                sessionCount: data.count,
                averageQuality: data.qualitySum / Double(data.count)
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Comparisons

    func getFeedingComparison(period: ComparisonPeriod) -> FeedingComparison {
        let days = period.daysInPeriod
        let now = Date()

        // Current period
        let currentStart = now.addingTimeInterval(-Double(days) * 24 * 3600)
        let currentNursing = nursingLogs.filter { $0.timestamp >= currentStart }.count
        let currentBottle = bottleFeedLogs.filter { $0.timestamp >= currentStart }.count
        let currentTotal = currentNursing + currentBottle

        // Previous period
        let previousStart = currentStart.addingTimeInterval(-Double(days) * 24 * 3600)
        let previousEnd = currentStart
        let previousNursing = nursingLogs.filter { $0.timestamp >= previousStart && $0.timestamp < previousEnd }.count
        let previousBottle = bottleFeedLogs.filter { $0.timestamp >= previousStart && $0.timestamp < previousEnd }.count
        let previousTotal = previousNursing + previousBottle

        return FeedingComparison(
            period: period,
            totalFeedings: PeriodComparison(current: currentTotal, previous: previousTotal),
            nursingCount: PeriodComparison(current: currentNursing, previous: previousNursing),
            bottleCount: PeriodComparison(current: currentBottle, previous: previousBottle),
            averagePerDay: PeriodComparison(
                current: Double(currentTotal) / Double(days),
                previous: Double(previousTotal) / Double(days)
            )
        )
    }

    func getSleepComparison(period: ComparisonPeriod) -> SleepComparison {
        let days = period.daysInPeriod
        let now = Date()

        // Current period
        let currentStart = now.addingTimeInterval(-Double(days) * 24 * 3600)
        let currentLogs = sleepLogs.filter { $0.startTime >= currentStart }
        let currentHours = currentLogs.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let currentCount = currentLogs.count
        let currentAvgQuality = currentLogs.isEmpty ? 0.0 : currentLogs.reduce(0.0) { $0 + qualityToDouble($1.quality) } / Double(currentCount)

        // Previous period
        let previousStart = currentStart.addingTimeInterval(-Double(days) * 24 * 3600)
        let previousEnd = currentStart
        let previousLogs = sleepLogs.filter { $0.startTime >= previousStart && $0.startTime < previousEnd }
        let previousHours = previousLogs.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let previousCount = previousLogs.count
        let previousAvgQuality = previousLogs.isEmpty ? 0.0 : previousLogs.reduce(0.0) { $0 + qualityToDouble($1.quality) } / Double(previousCount)

        return SleepComparison(
            period: period,
            totalHours: PeriodComparison(current: currentHours, previous: previousHours),
            sessionCount: PeriodComparison(current: currentCount, previous: previousCount),
            averageQuality: PeriodComparison(current: currentAvgQuality, previous: previousAvgQuality)
        )
    }

    private func qualityToDouble(_ quality: SleepQuality) -> Double {
        switch quality {
        case .poor: return 1.0
        case .fair: return 2.0
        case .good: return 3.0
        case .excellent: return 4.0
        }
    }

    // MARK: - Live Activities & Widgets

    @MainActor
    func startSleepActivity(babyName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Ensure we stop any existing activity first
        stopSleepActivity()

        let startTime = Date()
        let attributes = SleepActivityAttributes(babyName: babyName, startTime: startTime)
        let contentState = SleepActivityAttributes.ContentState(totalDuration: 0)

        // Update widget to show sleep is active
        WidgetDataManager.setActiveSleepStartTime(startTime)

        do {
            let _ = try Activity<SleepActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            print("Started Sleep Activity")
        } catch {
            print("Error launching activity: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    @MainActor
    func stopSleepActivity() {
        // Clear active sleep time in widget
        WidgetDataManager.setActiveSleepStartTime(nil)

        Task {
            for activity in Activity<SleepActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func updateWidgetData(lastFeed: Date, type: String) {
        if let defaults = UserDefaults(suiteName: "group.com.tinytastes.tracker") {
            defaults.set(lastFeed, forKey: "lastFeedTime")
            defaults.set(type, forKey: "lastFeedType")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Feed Reminder Notifications
    
    /// Calculate the next expected feed time based on recent feeding pattern
    private func calculateNextFeedTime() -> Date {
        // Get the most recent feed time
        let last24Hours = Date().addingTimeInterval(-24 * 3600)
        let recentNursing = nursingLogs.filter { $0.timestamp >= last24Hours }
        let recentBottle = bottleFeedLogs.filter { $0.timestamp >= last24Hours }
        
        let lastFeedTime = max(
            recentNursing.sorted { $0.timestamp < $1.timestamp }.last?.timestamp ?? .distantPast,
            recentBottle.sorted { $0.timestamp < $1.timestamp }.last?.timestamp ?? .distantPast
        )
        
        // 1. Check for manual user preference override
        let manualInterval = UserDefaults.standard.double(forKey: "feed_interval_hours")
        if manualInterval > 0 {
            if lastFeedTime > .distantPast {
                return lastFeedTime.addingTimeInterval(manualInterval * 3600)
            } else {
                return Date().addingTimeInterval(manualInterval * 3600)
            }
        }
        
        // 2. Fallback to historical average logic
        let allFeeds = (recentNursing.map { $0.timestamp } + recentBottle.map { $0.timestamp })
            .sorted()
        
        var intervals: [TimeInterval] = []
        if allFeeds.count > 1 {
            for i in 1..<allFeeds.count {
                let interval = allFeeds[i].timeIntervalSince(allFeeds[i-1])
                intervals.append(interval)
            }
        }
        
        let averageInterval: TimeInterval
        if !intervals.isEmpty {
            averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        } else {
            averageInterval = 3 * 3600
        }
        
        if lastFeedTime > .distantPast {
             return lastFeedTime.addingTimeInterval(averageInterval)
        } else {
             return Date().addingTimeInterval(averageInterval)
        }
    }
    
    /// Schedule a feed reminder notification if enabled
    func scheduleFeedReminderIfEnabled(childName: String) async {
        let nextFeedTime = calculateNextFeedTime()
        let leadTime = UserDefaults.standard.integer(forKey: "feed_notification_lead_time")
        let leadTimeMinutes = leadTime > 0 ? leadTime : 30

        await MainActor.run {
            guard notificationManager.feedNotificationsEnabled else { return }
            guard notificationManager.permissionStatus == .authorized else { return }

            Task {
                do {
                    try await notificationManager.scheduleFeedReminder(
                        nextFeedTime: nextFeedTime,
                        leadTimeMinutes: leadTimeMinutes,
                        childName: childName
                    )
                } catch {
                    print("Error scheduling feed reminder: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Data Loading

    func loadData(ownerId: String) {
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        listeners.append(nursingService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.nursingLogs = logs.sorted { $0.timestamp > $1.timestamp }
        })

        listeners.append(sleepService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.sleepLogs = logs.sorted { $0.startTime > $1.startTime }
        })

        listeners.append(diaperService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.diaperLogs = logs.sorted { $0.timestamp > $1.timestamp }
        })

        listeners.append(bottleService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.bottleFeedLogs = logs.sorted { $0.timestamp > $1.timestamp }
        })

        listeners.append(pumpingService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.pumpingLogs = logs.sorted { $0.timestamp > $1.timestamp }
        })

        listeners.append(medsService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.medicationLogs = logs.sorted { $0.timestamp > $1.timestamp }
        })

        listeners.append(growthService.addListener(forUserId: ownerId) { [weak self] logs in
            self?.growthMeasurements = logs.sorted { $0.date > $1.date }
        })

        listeners.append(savedMedsService.addListener(forUserId: ownerId) { [weak self] meds in
            self?.savedMedications = meds.sorted { $0.lastUsed > $1.lastUsed }
        })
    }

    // MARK: - Saved Medications

    func saveSavedMedication(medicineName: String, defaultDosage: String, notes: String? = nil, ownerId: String) async throws {
        let newId = UUID().uuidString
        let medication = SavedMedication(
            id: newId,
            ownerId: ownerId,
            medicineName: medicineName,
            defaultDosage: defaultDosage,
            notes: notes
        )

        // Optimistic Update
        self.savedMedications.append(medication)
        self.savedMedications.sort { $0.lastUsed > $1.lastUsed }

        guard NetworkMonitor.shared.isConnected else {
            if let encoded = try? JSONEncoder().encode(medication) {
                let operation = QueuedOperation(
                    type: .savedMedication,
                    payload: encoded,
                    priority: .normal
                )
                OfflineQueue.shared.enqueue(operation)
            }
            return
        }

        do {
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.savedMedsService.add(medication, withId: newId)
                }
            }
        } catch {
            if let index = self.savedMedications.firstIndex(where: { $0.id == newId }) {
                self.savedMedications.remove(at: index)
            }
            throw error
        }
    }

    func updateSavedMedicationUsage(_ medication: SavedMedication) {
        guard let id = medication.id else { return }

        var updated = medication
        updated.lastUsed = Date()
        updated.usageCount += 1

        // Optimistic update
        if let index = savedMedications.firstIndex(where: { $0.id == id }) {
            savedMedications[index] = updated
            savedMedications.sort { $0.lastUsed > $1.lastUsed }
        }

        // Save to Firestore (fire and forget)
        Task {
            guard NetworkMonitor.shared.isConnected else { return }
            try? await savedMedsService.update(updated)
        }
    }

    func deleteSavedMedication(_ medication: SavedMedication) {
        guard let id = medication.id else { return }

        // Optimistic update
        savedMedications.removeAll { $0.id == id }

        // Delete from Firestore (fire and forget)
        Task {
            guard NetworkMonitor.shared.isConnected else { return }
            try? await savedMedsService.delete(id: id)
        }
    }
}
