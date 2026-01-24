//
//  OnboardingUITests.swift
//  TinyTastesTrackerUITests
//
//  UI tests for onboarding flow
//

import XCTest

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding Flow Tests

    func testOnboardingAppears() throws {
        // Check if onboarding screen appears for new users
        let welcomeText = app.staticTexts["Welcome to Tiny Tastes Tracker"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
    }

    func testModeSelectionNewborn() throws {
        // Wait for mode selection screen
        let newbornButton = app.buttons["mode_newborn"]
        XCTAssertTrue(newbornButton.waitForExistence(timeout: 5))

        // Tap newborn mode
        newbornButton.tap()

        // Verify newborn UI elements appear
        let nursingButton = app.buttons["Log Nursing"]
        XCTAssertTrue(nursingButton.waitForExistence(timeout: 5))
    }

    func testModeSelectionExplorer() throws {
        let explorerButton = app.buttons["mode_explorer"]
        XCTAssertTrue(explorerButton.waitForExistence(timeout: 5))

        explorerButton.tap()

        // Verify explorer/food tracking UI appears
        let foodGridExists = app.collectionViews["food_grid"].waitForExistence(timeout: 5)
        XCTAssertTrue(foodGridExists)
    }

    func testModeSelectionToddler() throws {
        let toddlerButton = app.buttons["mode_toddler"]
        XCTAssertTrue(toddlerButton.waitForExistence(timeout: 5))

        toddlerButton.tap()

        // Verify toddler/meal planning UI appears
        let mealPlanExists = app.buttons["Meal Planner"].waitForExistence(timeout: 5)
        XCTAssertTrue(mealPlanExists)
    }

    func testProfileCreationFlow() throws {
        // Skip to profile creation if mode selected
        let nameField = app.textFields["baby_name_field"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("Test Baby")

            // Select birth date
            let datePickerExists = app.datePickers["birth_date_picker"].exists
            if datePickerExists {
                // Date picker interaction (simplified)
                app.datePickers["birth_date_picker"].tap()
            }

            // Select gender
            let genderBoyButton = app.buttons["gender_boy"]
            if genderBoyButton.exists {
                genderBoyButton.tap()
            }

            // Complete profile
            let completeButton = app.buttons["Complete Profile"]
            if completeButton.exists {
                completeButton.tap()

                // Verify main app screen appears
                XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
            }
        }
    }

    func testSkipOnboarding() throws {
        let skipButton = app.buttons["Skip"]
        if skipButton.exists {
            skipButton.tap()

            // Should still reach main app
            XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
        }
    }
}
