//
//  SnapshotUITests.swift
//  TinyTastesTrackerUITests
//
//  Automated App Store Screenshots
//

import XCTest

@MainActor final class SnapshotUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--screenshots"]
        // DISABLE sample data to prevent crash
        app.launchEnvironment = ["USE_SAMPLE_DATA": "1"]
        setupSnapshot(app)
        app.launch()
    }

    func testCaptureScreenshots() throws {

        // App launches in Newborn Mode (Emma) by default with sample data
        
        // 1. Snapshot Newborn Tracking Tab (Default Launch Screen)
        // Ensure we are on the Tracking tab (it's the first tab)
        
        // Wait for the tab bar to appear (handling initial launch delay)
        let trackingTab = app.tabBars.buttons["Tracking"]
        
        // Wait up to 30 seconds for the app to settle and show tabs
        XCTAssertTrue(trackingTab.waitForExistence(timeout: 30), "Tracking tab not found. App might be stuck on Onboarding or using a different identifier.")
        
        trackingTab.tap()
        snapshot("05_Tracking")
        
        // 2. Go to Profile to switch to Toddler Mode (Liam)
        // In Newborn mode, the tab is labeled "Profile and Settings Tab"
        let profileTab = app.tabBars.buttons["Profile and Settings Tab"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 10), "Profile tab not found")
        profileTab.tap()
            
        // Switch to Toddler (Liam)
        let modePicker = app.buttons["Application Mode Selection"]
        if modePicker.waitForExistence(timeout: 5) {
            modePicker.tap()
            let toddlerOption = app.buttons["Toddler (12m+)"]
            if toddlerOption.waitForExistence(timeout: 2) {
                toddlerOption.tap()
            }
        }

        // 3. Now in Toddler Mode -> Screenshot Balance Tab
        let balanceTab = app.tabBars.buttons["Balance"]
        if balanceTab.waitForExistence(timeout: 10) {
            balanceTab.tap()
            snapshot("01_Balance")
        }
        
        // 4. Snapshot Meal Builder (First Tab in Toddler Mode)
        let mealBuilderTab = app.tabBars.buttons["Meal Builder"]
        if mealBuilderTab.waitForExistence(timeout: 5) {
            mealBuilderTab.tap()
            snapshot("03_Meal_Builder")
        }
        
        // 5. Switch to Explorer Mode (Olivia)
        // We need to go back to Profile tab (Settings)
        let settingsTab = app.tabBars.buttons["Profile"] 
        // Note: Tab label might be "Profile" or "Settings" depending on mode, but ID is consistent in code? 
        // Code says .tabItem { Label("Profile", systemImage: "person.circle.fill") } for all modes in MainTabView
        if settingsTab.waitForExistence(timeout: 5) {
            settingsTab.tap()
            snapshot("04_Settings")
            
            let modePicker = app.buttons["Application Mode Selection"]
            if modePicker.waitForExistence(timeout: 5) {
                modePicker.tap()
                
                let explorerOption = app.buttons["Explorer (6-12m)"]
                if explorerOption.waitForExistence(timeout: 2) {
                    explorerOption.tap()
                }
            }
        }
        
        // 6. Snapshot 100 Foods (Explorer Mode -> Foods Tab)
        let foodsTab = app.tabBars.buttons["Foods"]
        if foodsTab.waitForExistence(timeout: 10) {
            foodsTab.tap()
            let header = app.staticTexts["100 Foods Challenge"]
            if header.waitForExistence(timeout: 5) {
                snapshot("02_Foods_List")
            }
        }
    }
}


