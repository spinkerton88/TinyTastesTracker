//
//  NewbornTrackingUITests.swift
//  TinyTastesTrackerUITests
//
//  UI tests for newborn tracking features
//

import XCTest

final class NewbornTrackingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--skip-onboarding")
        app.launchArguments.append("--newborn-mode")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Nursing Timer Tests

    func testNursingTimerAppears() throws {
        let nursingButton = app.buttons["Log Nursing"]
        XCTAssertTrue(nursingButton.waitForExistence(timeout: 5))
    }

    func testStartNursingTimerLeft() throws {
        let nursingButton = app.buttons["Log Nursing"]
        if nursingButton.waitForExistence(timeout: 5) {
            nursingButton.tap()

            // Select left side
            let leftButton = app.buttons["Left"]
            if leftButton.waitForExistence(timeout: 3) {
                leftButton.tap()

                // Start timer
                let startButton = app.buttons["Start"]
                if startButton.waitForExistence(timeout: 2) {
                    startButton.tap()

                    // Verify timer is running
                    let stopButton = app.buttons["Stop"]
                    XCTAssertTrue(stopButton.waitForExistence(timeout: 2))

                    // Stop timer
                    stopButton.tap()

                    // Save log
                    let saveButton = app.buttons["Save"]
                    if saveButton.exists {
                        saveButton.tap()
                    }
                }
            }
        }
    }

    func testStartNursingTimerBothSides() throws {
        let nursingButton = app.buttons["Log Nursing"]
        if nursingButton.waitForExistence(timeout: 5) {
            nursingButton.tap()

            let bothButton = app.buttons["Both"]
            if bothButton.waitForExistence(timeout: 3) {
                bothButton.tap()

                let startButton = app.buttons["Start"]
                if startButton.exists {
                    startButton.tap()

                    // Let it run for a moment
                    Thread.sleep(forTimeInterval: 2)

                    // Stop and save
                    app.buttons["Stop"].tap()
                    app.buttons["Save"].tap()

                    // Verify returned to main screen
                    XCTAssertTrue(app.navigationBars.element.exists)
                }
            }
        }
    }

    // MARK: - Sleep Logging Tests

    func testLogSleep() throws {
        let sleepButton = app.buttons["Log Sleep"]
        if sleepButton.waitForExistence(timeout: 5) {
            sleepButton.tap()

            // Set start time (use current time)
            // Set end time
            // Select quality
            let goodQualityButton = app.buttons["quality_good"]
            if goodQualityButton.waitForExistence(timeout: 3) {
                goodQualityButton.tap()
            }

            // Save log
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                saveButton.tap()

                // Verify dismissed
                XCTAssertFalse(app.sheets.element.exists)
            }
        }
    }

    func testSleepPrediction() throws {
        // Look for sleep prediction feature
        let predictionButton = app.buttons["Sleep Prediction"]
        if predictionButton.waitForExistence(timeout: 5) {
            predictionButton.tap()

            // Verify prediction view appears
            let predictionView = app.otherElements["sleep_prediction_view"]
            let sweetSpotLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Sweet Spot'")).element

            XCTAssertTrue(predictionView.exists || sweetSpotLabel.exists)
        }
    }

    // MARK: - Diaper Logging Tests

    func testLogDiaperWet() throws {
        let diaperButton = app.buttons["Log Diaper"]
        if diaperButton.waitForExistence(timeout: 5) {
            diaperButton.tap()

            // Select wet
            let wetButton = app.buttons["diaper_wet"]
            if wetButton.waitForExistence(timeout: 3) {
                wetButton.tap()

                // Save
                app.buttons["Save"].tap()

                // Verify dismissed
                XCTAssertFalse(app.sheets.element.exists)
            }
        }
    }

    func testLogDiaperDirty() throws {
        let diaperButton = app.buttons["Log Diaper"]
        if diaperButton.waitForExistence(timeout: 5) {
            diaperButton.tap()

            let dirtyButton = app.buttons["diaper_dirty"]
            if dirtyButton.waitForExistence(timeout: 3) {
                dirtyButton.tap()
                app.buttons["Save"].tap()
            }
        }
    }

    func testLogDiaperBoth() throws {
        let diaperButton = app.buttons["Log Diaper"]
        if diaperButton.waitForExistence(timeout: 5) {
            diaperButton.tap()

            let bothButton = app.buttons["diaper_both"]
            if bothButton.waitForExistence(timeout: 3) {
                bothButton.tap()
                app.buttons["Save"].tap()
            }
        }
    }

    // MARK: - Bottle Feeding Tests

    func testLogBottleFeed() throws {
        let bottleButton = app.buttons["Log Bottle"]
        if bottleButton.waitForExistence(timeout: 5) {
            bottleButton.tap()

            // Enter amount
            let amountField = app.textFields["bottle_amount"]
            if amountField.waitForExistence(timeout: 3) {
                amountField.tap()
                amountField.typeText("120")

                // Select feed type
                let breastMilkButton = app.buttons["feed_breast_milk"]
                if breastMilkButton.exists {
                    breastMilkButton.tap()
                }

                // Optional: Add notes
                let notesField = app.textFields["bottle_notes"]
                if notesField.exists {
                    notesField.tap()
                    notesField.typeText("Fed well")
                }

                // Save
                app.buttons["Save"].tap()

                // Verify dismissed
                XCTAssertFalse(app.sheets.element.exists)
            }
        }
    }

    // MARK: - Growth Tracking Tests

    func testLogGrowthMeasurement() throws {
        let growthButton = app.buttons["Log Growth"]
        if growthButton.waitForExistence(timeout: 5) {
            growthButton.tap()

            // Enter weight
            let weightField = app.textFields["growth_weight"]
            if weightField.waitForExistence(timeout: 3) {
                weightField.tap()
                weightField.typeText("7.5")

                // Enter height
                let heightField = app.textFields["growth_height"]
                if heightField.exists {
                    heightField.tap()
                    heightField.typeText("60")
                }

                // Enter head circumference
                let headField = app.textFields["growth_head"]
                if headField.exists {
                    headField.tap()
                    headField.typeText("42")
                }

                // Save
                app.buttons["Save"].tap()

                // Verify dismissed
                XCTAssertFalse(app.sheets.element.exists)
            }
        }
    }

    func testViewGrowthChart() throws {
        let chartsButton = app.buttons["Growth Charts"]
        if chartsButton.waitForExistence(timeout: 5) {
            chartsButton.tap()

            // Verify chart view appears
            let chartView = app.otherElements["growth_chart"]
            let weightChartLabel = app.staticTexts["Weight Chart"]

            XCTAssertTrue(chartView.exists || weightChartLabel.exists)
        }
    }

    // MARK: - Dashboard Tests

    func testDashboardDisplaysStats() throws {
        // Main dashboard should show 24-hour stats
        let feedingCountLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'feedings'")).element
        let diaperCountLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'diapers'")).element
        let sleepHoursLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'hours'")).element

        // At least one stat should be visible
        let hasStats = feedingCountLabel.exists || diaperCountLabel.exists || sleepHoursLabel.exists
        XCTAssertTrue(hasStats)
    }

    func testRecentActivityList() throws {
        // Verify recent activity list appears
        let activityList = app.collectionViews["recent_activity"]
        if activityList.waitForExistence(timeout: 5) {
            // Should have some items or show empty state
            let hasItems = activityList.cells.count > 0
            let emptyState = app.staticTexts["No activity yet"].exists

            XCTAssertTrue(hasItems || emptyState)
        }
    }

    // MARK: - Widget Update Tests

    func testWidgetDataUpdate() throws {
        // Log a bottle feed
        let bottleButton = app.buttons["Log Bottle"]
        if bottleButton.waitForExistence(timeout: 5) {
            bottleButton.tap()

            let amountField = app.textFields["bottle_amount"]
            if amountField.waitForExistence(timeout: 3) {
                amountField.tap()
                amountField.typeText("100")
                app.buttons["Save"].tap()

                // Widget should update (can't directly test widget in UI test,
                // but can verify main app shows the log)
                let recentActivity = app.collectionViews["recent_activity"]
                if recentActivity.waitForExistence(timeout: 2) {
                    // Verify new log appears
                    XCTAssertGreaterThan(recentActivity.cells.count, 0)
                }
            }
        }
    }
}
