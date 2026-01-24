//
//  NewbornManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for NewbornManager business logic
//

import XCTest
import SwiftData
@testable import TinyTastesTracker

final class NewbornManagerTests: XCTestCase {

    var manager: NewbornManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        manager = NewbornManager()

        // Create in-memory model container for testing
        let schema = Schema([
            NursingLog.self,
            SleepLog.self,
            DiaperLog.self,
            BottleFeedLog.self,
            GrowthMeasurement.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    override func tearDown() {
        manager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Nursing Log Tests

    func testSaveNursingLog() {
        let startTime = Date()
        let duration: TimeInterval = 600 // 10 minutes

        manager.saveNursingLog(startTime: startTime, duration: duration, side: .left, context: modelContext)

        XCTAssertEqual(manager.nursingLogs.count, 1)
        XCTAssertEqual(manager.nursingLogs.first?.timestamp, startTime)
        XCTAssertEqual(manager.nursingLogs.first?.duration, duration)
        XCTAssertEqual(manager.nursingLogs.first?.side, .left)
    }

    func testSaveNursingLogRightSide() {
        let startTime = Date()
        let duration: TimeInterval = 480 // 8 minutes

        manager.saveNursingLog(startTime: startTime, duration: duration, side: .right, context: modelContext)

        XCTAssertEqual(manager.nursingLogs.count, 1)
        XCTAssertEqual(manager.nursingLogs.first?.side, .right)
    }

    func testSaveNursingLogBothSides() {
        let startTime = Date()
        let duration: TimeInterval = 720 // 12 minutes

        manager.saveNursingLog(startTime: startTime, duration: duration, side: .both, context: modelContext)

        XCTAssertEqual(manager.nursingLogs.count, 1)
        XCTAssertEqual(manager.nursingLogs.first?.side, .both)
    }

    // MARK: - Sleep Log Tests

    func testSaveSleepLog() {
        let start = Date()
        let end = start.addingTimeInterval(7200) // 2 hours

        manager.saveSleepLog(start: start, end: end, quality: .good, context: modelContext)

        XCTAssertEqual(manager.sleepLogs.count, 1)
        XCTAssertEqual(manager.sleepLogs.first?.startTime, start)
        XCTAssertEqual(manager.sleepLogs.first?.endTime, end)
        XCTAssertEqual(manager.sleepLogs.first?.quality, .good)
    }

    func testSaveSleepLogWithDifferentQualities() {
        let start = Date()
        let end = start.addingTimeInterval(3600)

        manager.saveSleepLog(start: start, end: end, quality: .excellent, context: modelContext)
        manager.saveSleepLog(start: start, end: end, quality: .good, context: modelContext)
        manager.saveSleepLog(start: start, end: end, quality: .fair, context: modelContext)
        manager.saveSleepLog(start: start, end: end, quality: .poor, context: modelContext)

        XCTAssertEqual(manager.sleepLogs.count, 4)
        XCTAssertEqual(manager.sleepLogs[0].quality, .excellent)
        XCTAssertEqual(manager.sleepLogs[1].quality, .good)
        XCTAssertEqual(manager.sleepLogs[2].quality, .fair)
        XCTAssertEqual(manager.sleepLogs[3].quality, .poor)
    }

    // MARK: - Diaper Log Tests

    func testSaveDiaperLogWet() {
        manager.saveDiaperLog(type: .wet, context: modelContext)

        XCTAssertEqual(manager.diaperLogs.count, 1)
        XCTAssertEqual(manager.diaperLogs.first?.type, .wet)
    }

    func testSaveDiaperLogDirty() {
        manager.saveDiaperLog(type: .dirty, context: modelContext)

        XCTAssertEqual(manager.diaperLogs.count, 1)
        XCTAssertEqual(manager.diaperLogs.first?.type, .dirty)
    }

    func testSaveDiaperLogBoth() {
        manager.saveDiaperLog(type: .both, context: modelContext)

        XCTAssertEqual(manager.diaperLogs.count, 1)
        XCTAssertEqual(manager.diaperLogs.first?.type, .both)
    }

    func testSaveMultipleDiaperLogs() {
        manager.saveDiaperLog(type: .wet, context: modelContext)
        manager.saveDiaperLog(type: .dirty, context: modelContext)
        manager.saveDiaperLog(type: .both, context: modelContext)

        XCTAssertEqual(manager.diaperLogs.count, 3)
    }

    // MARK: - Bottle Feed Log Tests

    func testSaveBottleFeedLog() {
        manager.saveBottleFeedLog(amount: 120, feedType: .breastMilk, context: modelContext)

        XCTAssertEqual(manager.bottleFeedLogs.count, 1)
        XCTAssertEqual(manager.bottleFeedLogs.first?.amount, 120)
        XCTAssertEqual(manager.bottleFeedLogs.first?.feedType, .breastMilk)
    }

    func testSaveBottleFeedLogWithNotes() {
        let notes = "Took bottle well, seemed hungry"
        manager.saveBottleFeedLog(amount: 150, feedType: .formula, notes: notes, context: modelContext)

        XCTAssertEqual(manager.bottleFeedLogs.count, 1)
        XCTAssertEqual(manager.bottleFeedLogs.first?.notes, notes)
        XCTAssertEqual(manager.bottleFeedLogs.first?.feedType, .formula)
    }

    func testSaveBottleFeedLogWithoutNotes() {
        manager.saveBottleFeedLog(amount: 100, feedType: .breastMilk, notes: nil, context: modelContext)

        XCTAssertEqual(manager.bottleFeedLogs.count, 1)
        XCTAssertNil(manager.bottleFeedLogs.first?.notes)
    }

    // MARK: - Growth Measurement Tests

    func testSaveGrowthMeasurementComplete() {
        manager.saveGrowthMeasurement(
            weight: 7.5,
            height: 58.0,
            headCircumference: 42.0,
            notes: "Regular checkup",
            context: modelContext
        )

        XCTAssertEqual(manager.growthMeasurements.count, 1)
        XCTAssertEqual(manager.growthMeasurements.first?.weight, 7.5)
        XCTAssertEqual(manager.growthMeasurements.first?.height, 58.0)
        XCTAssertEqual(manager.growthMeasurements.first?.headCircumference, 42.0)
        XCTAssertEqual(manager.growthMeasurements.first?.notes, "Regular checkup")
    }

    func testSaveGrowthMeasurementWeightOnly() {
        manager.saveGrowthMeasurement(
            weight: 8.0,
            height: nil,
            headCircumference: nil,
            notes: nil,
            context: modelContext
        )

        XCTAssertEqual(manager.growthMeasurements.count, 1)
        XCTAssertEqual(manager.growthMeasurements.first?.weight, 8.0)
        XCTAssertNil(manager.growthMeasurements.first?.height)
        XCTAssertNil(manager.growthMeasurements.first?.headCircumference)
    }

    func testSaveGrowthMeasurementPartial() {
        manager.saveGrowthMeasurement(
            weight: 7.8,
            height: 59.0,
            headCircumference: nil,
            notes: "Missed head measurement",
            context: modelContext
        )

        XCTAssertEqual(manager.growthMeasurements.count, 1)
        XCTAssertEqual(manager.growthMeasurements.first?.weight, 7.8)
        XCTAssertEqual(manager.growthMeasurements.first?.height, 59.0)
        XCTAssertNil(manager.growthMeasurements.first?.headCircumference)
    }

    // MARK: - Statistics Tests

    func testLast24HourStatsEmpty() {
        let stats = manager.last24HourStats

        XCTAssertEqual(stats.feedingCount, 0)
        XCTAssertEqual(stats.diaperCount, 0)
        XCTAssertEqual(stats.totalSleepHours, 0.0)
    }

    func testLast24HourStatsWithFeedings() {
        let now = Date()

        // Add feedings within last 24 hours
        manager.saveNursingLog(startTime: now.addingTimeInterval(-3600), duration: 600, side: .left, context: modelContext)
        manager.saveNursingLog(startTime: now.addingTimeInterval(-7200), duration: 600, side: .right, context: modelContext)
        manager.saveBottleFeedLog(amount: 120, feedType: .formula, context: modelContext)

        let stats = manager.last24HourStats

        XCTAssertEqual(stats.feedingCount, 3)
    }

    func testLast24HourStatsWithDiapers() {
        // Add diapers
        manager.saveDiaperLog(type: .wet, context: modelContext)
        manager.saveDiaperLog(type: .dirty, context: modelContext)
        manager.saveDiaperLog(type: .both, context: modelContext)

        let stats = manager.last24HourStats

        XCTAssertEqual(stats.diaperCount, 3)
    }

    func testLast24HourStatsWithSleep() {
        let now = Date()

        // Add sleep logs (2 hours each = 4 hours total)
        manager.saveSleepLog(
            start: now.addingTimeInterval(-7200),
            end: now.addingTimeInterval(-3600),
            quality: .good,
            context: modelContext
        )
        manager.saveSleepLog(
            start: now.addingTimeInterval(-3600),
            end: now,
            quality: .excellent,
            context: modelContext
        )

        let stats = manager.last24HourStats

        XCTAssertEqual(stats.totalSleepHours, 4.0, accuracy: 0.1)
    }

    func testLast24HourStatsExcludesOldData() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-25 * 3600) // 25 hours ago

        // Add old data (should be excluded)
        manager.saveNursingLog(startTime: yesterday, duration: 600, side: .left, context: modelContext)
        manager.saveDiaperLog(type: .wet, context: modelContext)

        // Manually set timestamp to old date for diaper log
        if let diaperLog = manager.diaperLogs.first {
            diaperLog.timestamp = yesterday
        }

        // Add recent data
        manager.saveNursingLog(startTime: now.addingTimeInterval(-3600), duration: 600, side: .right, context: modelContext)

        let stats = manager.last24HourStats

        // Should only count the recent feeding (1), not the old one
        XCTAssertEqual(stats.feedingCount, 1)
        XCTAssertEqual(stats.diaperCount, 0)
    }

    // MARK: - Daily Feeding Data Tests

    func testGetDailyFeedingDataEmpty() {
        let data = manager.getDailyFeedingData(days: 7)

        XCTAssertEqual(data.count, 0)
    }

    func testGetDailyFeedingDataWithLogs() {
        let now = Date()

        // Add various feeding logs
        manager.saveNursingLog(startTime: now, duration: 600, side: .left, context: modelContext)
        manager.saveNursingLog(startTime: now, duration: 600, side: .right, context: modelContext)
        manager.saveBottleFeedLog(amount: 120, feedType: .formula, context: modelContext)

        let data = manager.getDailyFeedingData(days: 7)

        XCTAssertGreaterThan(data.count, 0)
        // Should have at least one day with data
        if let todayData = data.first {
            XCTAssertEqual(todayData.nursingCount + todayData.bottleCount, 3)
        }
    }

    func testGetDailyFeedingDataSorted() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 3600)

        // Add logs for different days
        manager.saveNursingLog(startTime: now, duration: 600, side: .left, context: modelContext)
        manager.saveNursingLog(startTime: yesterday, duration: 600, side: .right, context: modelContext)

        let data = manager.getDailyFeedingData(days: 7)

        // Data should be sorted chronologically
        if data.count > 1 {
            XCTAssertLessThan(data[0].date, data[1].date)
        }
    }

    // MARK: - Weekly Sleep Data Tests

    func testGetWeeklySleepDataEmpty() {
        let data = manager.getWeeklySleepData()

        XCTAssertEqual(data.count, 0)
    }

    func testGetWeeklySleepDataWithLogs() {
        let now = Date()
        let start = now.addingTimeInterval(-7200)

        manager.saveSleepLog(start: start, end: now, quality: .good, context: modelContext)

        let data = manager.getWeeklySleepData()

        XCTAssertGreaterThan(data.count, 0)
    }
}
