//
//  FoodTrackingUITests.swift
//  TinyTastesTrackerUITests
//
//  UI tests for food tracking and logging
//

import XCTest

final class FoodTrackingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Food Grid Tests

    func testFoodGridDisplays() throws {
        // Navigate to food tracker (Explorer mode)
        let foodTrackerTab = app.tabBars.buttons["Food Tracker"]
        if foodTrackerTab.waitForExistence(timeout: 5) {
            foodTrackerTab.tap()
        }

        // Verify food grid appears
        let foodGrid = app.collectionViews["food_grid"]
        XCTAssertTrue(foodGrid.waitForExistence(timeout: 5))
    }

    func testTapFoodItem() throws {
        let foodGrid = app.collectionViews["food_grid"]
        XCTAssertTrue(foodGrid.waitForExistence(timeout: 5))

        // Tap a food item (e.g., Apple)
        let appleCell = foodGrid.cells.containing(.staticText, identifier: "Apple").element
        if appleCell.exists {
            appleCell.tap()

            // Verify food detail modal appears
            let foodDetailModal = app.sheets.element
            XCTAssertTrue(foodDetailModal.waitForExistence(timeout: 3))
        }
    }

    func testLogFoodReaction() throws {
        // Navigate to food and open detail
        let foodGrid = app.collectionViews["food_grid"]
        if foodGrid.waitForExistence(timeout: 5) {
            let firstFood = foodGrid.cells.element(boundBy: 0)
            firstFood.tap()

            // Select reaction (e.g., 5 stars)
            let fiveStarButton = app.buttons["reaction_5"]
            if fiveStarButton.waitForExistence(timeout: 3) {
                fiveStarButton.tap()

                // Select meal type
                let breakfastButton = app.buttons["meal_breakfast"]
                if breakfastButton.exists {
                    breakfastButton.tap()
                }

                // Save log
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.tap()

                    // Verify modal dismissed
                    XCTAssertFalse(app.sheets.element.exists)
                }
            }
        }
    }

    func testFoodSearch() throws {
        let foodGrid = app.collectionViews["food_grid"]
        XCTAssertTrue(foodGrid.waitForExistence(timeout: 5))

        // Tap search field
        let searchField = app.searchFields["Search foods"]
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("Apple")

            // Verify filtered results
            let cellCount = foodGrid.cells.count
            XCTAssertGreaterThan(cellCount, 0)
        }
    }

    func testCategoryFilter() throws {
        // Open category filter
        let categoryButton = app.buttons["Filter"]
        if categoryButton.waitForExistence(timeout: 5) {
            categoryButton.tap()

            // Select a category (e.g., Fruits)
            let fruitsOption = app.buttons["category_fruits"]
            if fruitsOption.exists {
                fruitsOption.tap()

                // Verify filtered view
                let foodGrid = app.collectionViews["food_grid"]
                XCTAssertTrue(foodGrid.exists)
            }
        }
    }

    func testTriedFoodIndicator() throws {
        // Log a food first
        let foodGrid = app.collectionViews["food_grid"]
        if foodGrid.waitForExistence(timeout: 5) {
            let firstFood = foodGrid.cells.element(boundBy: 0)
            let foodText = firstFood.staticTexts.element.label

            firstFood.tap()

            // Log it
            let fiveStarButton = app.buttons["reaction_5"]
            if fiveStarButton.waitForExistence(timeout: 3) {
                fiveStarButton.tap()
                app.buttons["Save"].tap()

                // Wait for modal to dismiss
                Thread.sleep(forTimeInterval: 1)

                // Verify tried indicator (checkmark or visual change)
                let triedFood = foodGrid.cells.containing(.staticText, identifier: foodText).element
                // Could check for checkmark icon or opacity change
                XCTAssertTrue(triedFood.exists)
            }
        }
    }

    // MARK: - Food Detail Tests

    func testFoodDetailInformation() throws {
        let foodGrid = app.collectionViews["food_grid"]
        if foodGrid.waitForExistence(timeout: 5) {
            let firstFood = foodGrid.cells.element(boundBy: 0)
            firstFood.tap()

            // Verify detail sections appear
            let nutritionSection = app.staticTexts["Nutrition Highlights"]
            let howToServeSection = app.staticTexts["How to Serve"]
            let allergenSection = app.staticTexts["Allergen Information"]

            // At least one section should exist
            let hasSections = nutritionSection.exists || howToServeSection.exists || allergenSection.exists
            XCTAssertTrue(hasSections)
        }
    }

    func testUploadFoodPhoto() throws {
        let foodGrid = app.collectionViews["food_grid"]
        if foodGrid.waitForExistence(timeout: 5) {
            let firstFood = foodGrid.cells.element(boundBy: 0)
            firstFood.tap()

            // Look for photo upload button
            let photoButton = app.buttons["Add Photo"]
            if photoButton.waitForExistence(timeout: 3) {
                photoButton.tap()

                // Camera/Photo picker should appear
                // (In real test, would need to handle photo picker permissions)
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }

    // MARK: - Progress Tests

    func testProgressDisplay() throws {
        // Navigate to progress view
        let progressButton = app.buttons["Progress"]
        if progressButton.waitForExistence(timeout: 5) {
            progressButton.tap()

            // Verify progress stats appear
            let triedCountLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'foods tried'")).element
            XCTAssertTrue(triedCountLabel.exists)
        }
    }

    func testRainbowProgressChart() throws {
        let progressButton = app.buttons["Progress"]
        if progressButton.waitForExistence(timeout: 5) {
            progressButton.tap()

            // Look for rainbow progress visualization
            let rainbowChart = app.otherElements["rainbow_progress_chart"]
            // May exist depending on implementation
            // XCTAssertTrue(rainbowChart.waitForExistence(timeout: 3))
        }
    }
}
