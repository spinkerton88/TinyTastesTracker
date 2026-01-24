//
//  NewbornManager.swift
//  TinyTastesTracker
//

import Foundation
import SwiftUI
import SwiftData
import ActivityKit
import WidgetKit

@Observable
class NewbornManager {
    var nursingLogs: [NursingLog] = []
    var sleepLogs: [SleepLog] = []
    var diaperLogs: [DiaperLog] = []
    var bottleFeedLogs: [BottleFeedLog] = []
    var pumpingLogs: [PumpingLog] = []
    var medicationLogs: [MedicationLog] = []
    var growthMeasurements: [GrowthMeasurement] = []

    // MARK: - Save Methods

    func saveNursingLog(startTime: Date, duration: TimeInterval, side: NursingSide, context: ModelContext, userProfile: UserProfile? = nil) {
        let log = NursingLog(timestamp: startTime, duration: duration, side: side)
        nursingLogs.append(log)
        context.insert(log)
        try? context.save()

        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .nursing, time: startTime)
        
        // Schedule feed reminder notification
        if let profile = userProfile {
            Task {
                await scheduleFeedReminderIfEnabled(childName: profile.babyName)
            }
        }
    }

    func saveSleepLog(start: Date, end: Date, quality: SleepQuality, context: ModelContext) {
        let log = SleepLog(startTime: start, endTime: end, quality: quality)
        sleepLogs.append(log)
        context.insert(log)
        try? context.save()

        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .sleep, time: end)
    }

    func saveDiaperLog(type: DiaperType, context: ModelContext) {
        let log = DiaperLog(timestamp: Date(), type: type)
        diaperLogs.append(log)
        context.insert(log)
        try? context.save()

        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .diaper, time: log.timestamp)
    }

    func saveBottleFeedLog(amount: Double, feedType: FeedingType, notes: String? = nil, context: ModelContext, userProfile: UserProfile? = nil) {
        let log = BottleFeedLog(timestamp: Date(), amount: amount, feedType: feedType, notes: notes)
        bottleFeedLogs.append(log)
        context.insert(log)
        try? context.save()

        // Update Widgets
        updateWidgetData(lastFeed: log.timestamp, type: feedType.rawValue) // For existing LastFeedWidget
        WidgetDataManager.saveLastLogTime(type: .bottle, time: log.timestamp) // For new QuickLogWidget
        
        // Schedule feed reminder notification
        if let profile = userProfile {
            Task {
                await scheduleFeedReminderIfEnabled(childName: profile.babyName)
            }
        }
    }
    
    func savePumpingLog(leftBreastOz: Double, rightBreastOz: Double, notes: String? = nil, context: ModelContext) {
        let log = PumpingLog(timestamp: Date(), leftBreastOz: leftBreastOz, rightBreastOz: rightBreastOz, notes: notes)
        pumpingLogs.append(log)
        context.insert(log)
        try? context.save()
        
        // Update Widget
        WidgetDataManager.saveLastLogTime(type: .bottle, time: log.timestamp) // Treat as bottle for widget purposes
    }
    
    func saveMedicationLog(medicineName: String, babyWeight: Double, dosage: String, safetyInfo: String? = nil, notes: String? = nil, context: ModelContext) {
        let log = MedicationLog(timestamp: Date(), medicineName: medicineName, babyWeight: babyWeight, dosage: dosage, safetyInfo: safetyInfo, notes: notes)
        medicationLogs.append(log)
        context.insert(log)
        try? context.save()
    }

    func saveGrowthMeasurement(weight: Double?, height: Double?, headCircumference: Double?, notes: String? = nil, context: ModelContext) {
        let measurement = GrowthMeasurement(date: Date(), weight: weight, height: height, headCircumference: headCircumference, notes: notes)
        growthMeasurements.append(measurement)
        context.insert(measurement)
        try? context.save()
    }

    // MARK: - Delete Methods
    
    func deleteNursingLog(_ log: NursingLog, context: ModelContext) {
        context.delete(log)
        nursingLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deleteSleepLog(_ log: SleepLog, context: ModelContext) {
        context.delete(log)
        sleepLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deleteDiaperLog(_ log: DiaperLog, context: ModelContext) {
        context.delete(log)
        diaperLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deleteBottleFeedLog(_ log: BottleFeedLog, context: ModelContext) {
        context.delete(log)
        bottleFeedLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deletePumpingLog(_ log: PumpingLog, context: ModelContext) {
        context.delete(log)
        pumpingLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deleteMedicationLog(_ log: MedicationLog, context: ModelContext) {
        context.delete(log)
        medicationLogs.removeAll { $0.id == log.id }
        try? context.save()
    }
    
    func deleteGrowthMeasurement(_ measurement: GrowthMeasurement, context: ModelContext) {
        context.delete(measurement)
        growthMeasurements.removeAll { $0.id == measurement.id }
        try? context.save()
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
            ErrorPresenter.shared.present(error)
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
            // Default logic if no feed exists yet: start from now? Or just return distantPast?
            // If distantPast, we can't schedule.
            // If we have a last feed, add interval.
            if lastFeedTime > .distantPast {
                return lastFeedTime.addingTimeInterval(manualInterval * 3600)
            } else {
                // If no feeds, maybe assume "now" is the baseline?
                // Or better, just don't schedule if we don't know when the last feed was.
                return Date().addingTimeInterval(manualInterval * 3600)
            }
        }
        
        // 2. Fallback to historical average logic
        
        // Combine and sort all feeds
        let allFeeds = (recentNursing.map { $0.timestamp } + recentBottle.map { $0.timestamp })
            .sorted()
        
        // Calculate average interval between feeds
        var intervals: [TimeInterval] = []
        for i in 1..<allFeeds.count {
            let interval = allFeeds[i].timeIntervalSince(allFeeds[i-1])
            intervals.append(interval)
        }
        
        // Use average interval, or default to 3 hours if no pattern
        let averageInterval: TimeInterval
        if !intervals.isEmpty {
            averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        } else {
            // Default to 3 hours for newborns
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
        // Calculate next feed time
        let nextFeedTime = calculateNextFeedTime()
        
        // Get lead time from settings
        let leadTime = UserDefaults.standard.integer(forKey: "feed_notification_lead_time")
        let leadTimeMinutes = leadTime > 0 ? leadTime : 30 // Default to 30 minutes
        
        // Schedule the notification on main actor
        await MainActor.run {
            let notificationManager = NotificationManager.shared
            
            // Check if feed notifications are enabled
            guard notificationManager.feedNotificationsEnabled else {
                return
            }
            
            // Check if permissions are granted
            guard notificationManager.permissionStatus == .authorized else {
                return
            }
            
            // Schedule the notification
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

    func loadData(context: ModelContext) {
        do {
            // Performance optimization: Load only last 30 days of data initially
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            let nursingDescriptor = FetchDescriptor<NursingLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            nursingLogs = try context.fetch(nursingDescriptor)

            let sleepDescriptor = FetchDescriptor<SleepLog>(
                predicate: #Predicate { $0.startTime >= cutoffDate },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            sleepLogs = try context.fetch(sleepDescriptor)

            let diaperDescriptor = FetchDescriptor<DiaperLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            diaperLogs = try context.fetch(diaperDescriptor)

            let bottleDescriptor = FetchDescriptor<BottleFeedLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            bottleFeedLogs = try context.fetch(bottleDescriptor)
            
            let pumpingDescriptor = FetchDescriptor<PumpingLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            pumpingLogs = try context.fetch(pumpingDescriptor)
            
            let medicationDescriptor = FetchDescriptor<MedicationLog>(
                predicate: #Predicate { $0.timestamp >= cutoffDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            medicationLogs = try context.fetch(medicationDescriptor)

            let growthDescriptor = FetchDescriptor<GrowthMeasurement>(
                predicate: #Predicate { $0.date >= cutoffDate },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            growthMeasurements = try context.fetch(growthDescriptor)
        } catch {
            print("Error loading newborn data: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
    
    /// Load historical data beyond the initial 30-day window
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - beforeDate: Load data before this date
    func loadHistoricalData(context: ModelContext, beforeDate: Date) {
        do {
            // Load older nursing logs
            let nursingDescriptor = FetchDescriptor<NursingLog>(
                predicate: #Predicate { $0.timestamp < beforeDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let olderNursing = try context.fetch(nursingDescriptor)
            nursingLogs.append(contentsOf: olderNursing)
            
            // Load older sleep logs
            let sleepDescriptor = FetchDescriptor<SleepLog>(
                predicate: #Predicate { $0.startTime < beforeDate },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            let olderSleep = try context.fetch(sleepDescriptor)
            sleepLogs.append(contentsOf: olderSleep)
            
            // Load older diaper logs
            let diaperDescriptor = FetchDescriptor<DiaperLog>(
                predicate: #Predicate { $0.timestamp < beforeDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let olderDiaper = try context.fetch(diaperDescriptor)
            diaperLogs.append(contentsOf: olderDiaper)
            
            // Load older bottle logs
            let bottleDescriptor = FetchDescriptor<BottleFeedLog>(
                predicate: #Predicate { $0.timestamp < beforeDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let olderBottle = try context.fetch(bottleDescriptor)
            bottleFeedLogs.append(contentsOf: olderBottle)
            
            // Load older growth measurements
            let growthDescriptor = FetchDescriptor<GrowthMeasurement>(
                predicate: #Predicate { $0.date < beforeDate },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let olderGrowth = try context.fetch(growthDescriptor)
            growthMeasurements.append(contentsOf: olderGrowth)
        } catch {
            print("Error loading historical newborn data: \(error)")
            ErrorPresenter.shared.present(error)
        }
    }
}
