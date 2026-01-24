//
//  OnboardingFlowUITests.swift
//  TinyTastesTrackerUITests
//
//  Comprehensive UI tests for onboarding flow validation
//

import XCTest

final class OnboardingFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Reset app state for clean testing
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["RESET_USER_DEFAULTS": "1"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Mode Selection Tests
    
    func testModeSelection_Newborn() throws {
        app.launch()
        
        // Should show welcome screen first
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes Tracker"].waitForExistence(timeout: 5))
        
        // Tap "Start Fresh" to skip sample data
        let startFreshButton = app.buttons["Start Fresh"]
        XCTAssertTrue(startFreshButton.exists)
        startFreshButton.tap()
        
        // Should show mode selection
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes"].waitForExistence(timeout: 2))
        
        // Select Newborn mode
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        XCTAssertTrue(newbornButton.exists)
        newbornButton.tap()
        
        // Should navigate to profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
        
        // Verify birthdate defaults to today (for newborn)
        XCTAssertTrue(app.datePickers.firstMatch.exists)
    }
    
    func testModeSelection_Explorer() throws {
        app.launch()
        
        // Skip to mode selection
        app.buttons["Start Fresh"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes"].waitForExistence(timeout: 2))
        
        // Select Explorer mode
        let explorerButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Explorer'")).firstMatch
        XCTAssertTrue(explorerButton.exists)
        explorerButton.tap()
        
        // Should navigate to profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
    }
    
    func testModeSelection_Toddler() throws {
        app.launch()
        
        // Skip to mode selection
        app.buttons["Start Fresh"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes"].waitForExistence(timeout: 2))
        
        // Select Toddler mode
        let toddlerButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Toddler'")).firstMatch
        XCTAssertTrue(toddlerButton.exists)
        toddlerButton.tap()
        
        // Should navigate to profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Profile Setup Tests
    
    func testProfileSetup_ValidData() throws {
        app.launch()
        
        // Navigate to profile setup
        app.buttons["Start Fresh"].tap()
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        // Wait for profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
        
        // Enter baby name
        let nameField = app.textFields["Baby's Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Emma")
        
        // Select gender
        let genderPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(genderPicker.exists)
        genderPicker.buttons["Girl"].tap()
        
        // Tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        XCTAssertTrue(getStartedButton.isEnabled)
        getStartedButton.tap()
        
        // Should show feature tour or main app
        let tourExists = app.staticTexts["Meet Sage AI"].waitForExistence(timeout: 3)
        let mainAppExists = app.tabBars.firstMatch.waitForExistence(timeout: 3)
        
        XCTAssertTrue(tourExists || mainAppExists, "Should navigate to feature tour or main app")
    }
    
    func testProfileSetup_EmptyName() throws {
        app.launch()
        
        // Navigate to profile setup
        app.buttons["Start Fresh"].tap()
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        // Wait for profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
        
        // Don't enter name, just try to submit
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        
        // Button should be disabled with empty name
        XCTAssertFalse(getStartedButton.isEnabled, "Get Started button should be disabled when name is empty")
    }
    
    func testProfileSetup_BackNavigation() throws {
        app.launch()
        
        // Navigate to profile setup
        app.buttons["Start Fresh"].tap()
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        // Wait for profile setup
        XCTAssertTrue(app.staticTexts["Tell us about your little one"].waitForExistence(timeout: 2))
        
        // Tap Back button
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.exists)
        backButton.tap()
        
        // Should return to mode selection
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Sample Data Tests
    
    func testSampleDataLoading() throws {
        app.launch()
        
        // Should show welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes Tracker"].waitForExistence(timeout: 5))
        
        // Tap "Explore with Sample Data"
        let sampleDataButton = app.buttons["Explore with Sample Data"]
        XCTAssertTrue(sampleDataButton.exists)
        sampleDataButton.tap()
        
        // Should show loading indicator
        let loadingText = app.staticTexts["Loading sample data..."]
        XCTAssertTrue(loadingText.waitForExistence(timeout: 2))
        
        // Wait for loading to complete (max 5 seconds)
        let mainApp = app.tabBars.firstMatch
        XCTAssertTrue(mainApp.waitForExistence(timeout: 5), "App should load with sample data")
        
        // Verify we're in the main app
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    func testFreshStartFlow() throws {
        app.launch()
        
        // Should show welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes Tracker"].waitForExistence(timeout: 5))
        
        // Tap "Start Fresh"
        let startFreshButton = app.buttons["Start Fresh"]
        XCTAssertTrue(startFreshButton.exists)
        startFreshButton.tap()
        
        // Should navigate to mode selection immediately
        XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes"].waitForExistence(timeout: 2))
        
        // Complete onboarding
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        let nameField = app.textFields["Baby's Name"]
        nameField.tap()
        nameField.typeText("Test Baby")
        
        app.buttons["Get Started"].tap()
        
        // Should eventually reach main app
        let mainApp = app.tabBars.firstMatch
        XCTAssertTrue(mainApp.waitForExistence(timeout: 5))
    }
    
    // MARK: - Feature Tour Tests
    
    func testFeatureTourNavigation() throws {
        app.launch()
        
        // Complete onboarding to trigger feature tour
        app.buttons["Start Fresh"].tap()
        
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        let nameField = app.textFields["Baby's Name"]
        nameField.tap()
        nameField.typeText("Tour Test")
        
        app.buttons["Get Started"].tap()
        
        // Should show feature tour
        let tourTitle = app.staticTexts["Meet Sage AI"]
        if tourTitle.waitForExistence(timeout: 3) {
            // Tour is showing, test navigation
            XCTAssertTrue(tourTitle.exists)
            
            // Tap Next button
            let nextButton = app.buttons["Next"]
            XCTAssertTrue(nextButton.exists)
            nextButton.tap()
            
            // Should advance to next page
            XCTAssertTrue(app.staticTexts["Track Every Meal"].waitForExistence(timeout: 2))
            
            // Test Skip button
            let skipButton = app.buttons["Skip"]
            XCTAssertTrue(skipButton.exists)
            skipButton.tap()
            
            // Should navigate to welcome screen
            XCTAssertTrue(app.staticTexts["Welcome to Tiny Tastes Tracker"].waitForExistence(timeout: 2))
        }
    }
    
    func testFeatureTourCompletion() throws {
        app.launch()
        
        // Complete onboarding
        app.buttons["Start Fresh"].tap()
        
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        let nameField = app.textFields["Baby's Name"]
        nameField.tap()
        nameField.typeText("Complete Test")
        
        app.buttons["Get Started"].tap()
        
        // If tour appears, complete it
        let tourTitle = app.staticTexts["Meet Sage AI"]
        if tourTitle.waitForExistence(timeout: 3) {
            // Navigate through all pages
            for _ in 0..<5 {
                let nextButton = app.buttons["Next"]
                if nextButton.exists {
                    nextButton.tap()
                    sleep(1) // Brief pause between pages
                }
            }
            
            // Last page should have "Get Started" button
            let getStartedButton = app.buttons["Get Started"]
            if getStartedButton.exists {
                getStartedButton.tap()
            }
        }
    }
    
    // MARK: - Onboarding Completion Tests
    
    func testOnboardingCompletion_CreatesProfile() throws {
        app.launch()
        
        // Complete full onboarding
        app.buttons["Start Fresh"].tap()
        
        let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
        newbornButton.tap()
        
        let nameField = app.textFields["Baby's Name"]
        nameField.tap()
        nameField.typeText("Completion Test")
        
        app.buttons["Get Started"].tap()
        
        // Skip tour if it appears
        if app.buttons["Skip"].waitForExistence(timeout: 2) {
            app.buttons["Skip"].tap()
        }
        
        // Skip welcome if it appears
        if app.buttons["Start Fresh"].waitForExistence(timeout: 2) {
            app.buttons["Start Fresh"].tap()
        }
        
        // Should eventually reach main app
        let mainApp = app.tabBars.firstMatch
        XCTAssertTrue(mainApp.waitForExistence(timeout: 5), "Should reach main app after onboarding")
        
        // Verify profile was created by checking settings
        let settingsTab = app.tabBars.buttons["Profile"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Should show profile name
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Completion Test'")).firstMatch.waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - Performance Tests
    
    func testOnboardingPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            app.launch()
            
            // Complete onboarding as fast as possible
            app.buttons["Start Fresh"].tap()
            
            let newbornButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Newborn'")).firstMatch
            newbornButton.tap()
            
            let nameField = app.textFields["Baby's Name"]
            nameField.tap()
            nameField.typeText("Perf Test")
            
            app.buttons["Get Started"].tap()
            
            // Wait for completion
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
            
            app.terminate()
        }
    }
}
