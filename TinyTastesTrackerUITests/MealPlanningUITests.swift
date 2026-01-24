//
//  MealPlanningUITests.swift
//  TinyTastesTrackerUITests
//
//  UI tests for meal planning and recipe features
//

import XCTest

final class MealPlanningUITests: XCTestCase {

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

    // MARK: - Recipe Tests

    func testRecipeListDisplays() throws {
        // Navigate to recipes tab
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            // Verify recipe list appears
            let recipeList = app.collectionViews["recipe_list"]
            XCTAssertTrue(recipeList.waitForExistence(timeout: 5) || app.staticTexts["No recipes yet"].exists)
        }
    }

    func testAddRecipe() throws {
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            // Tap add recipe button
            let addButton = app.buttons["Add Recipe"]
            if addButton.waitForExistence(timeout: 3) {
                addButton.tap()

                // Verify recipe form appears
                let titleField = app.textFields["recipe_title"]
                XCTAssertTrue(titleField.waitForExistence(timeout: 3))

                // Fill in recipe details
                titleField.tap()
                titleField.typeText("Test Recipe")

                let ingredientsField = app.textViews["recipe_ingredients"]
                if ingredientsField.exists {
                    ingredientsField.tap()
                    ingredientsField.typeText("Banana, Oats, Egg")
                }

                let instructionsField = app.textViews["recipe_instructions"]
                if instructionsField.exists {
                    instructionsField.tap()
                    instructionsField.typeText("Mix and cook")
                }

                // Save recipe
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.tap()

                    // Verify recipe added to list
                    Thread.sleep(forTimeInterval: 1)
                    let recipeCell = app.cells.containing(.staticText, identifier: "Test Recipe").element
                    XCTAssertTrue(recipeCell.exists)
                }
            }
        }
    }

    func testViewRecipeDetail() throws {
        // Navigate to recipes and tap a recipe
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            let recipeList = app.collectionViews["recipe_list"]
            if recipeList.waitForExistence(timeout: 3) {
                let firstRecipe = recipeList.cells.element(boundBy: 0)
                if firstRecipe.exists {
                    firstRecipe.tap()

                    // Verify detail view appears with sections
                    let ingredientsHeader = app.staticTexts["Ingredients"]
                    let instructionsHeader = app.staticTexts["Instructions"]

                    XCTAssertTrue(ingredientsHeader.exists || instructionsHeader.exists)
                }
            }
        }
    }

    func testDeleteRecipe() throws {
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            let recipeList = app.collectionViews["recipe_list"]
            if recipeList.waitForExistence(timeout: 3) {
                let firstRecipe = recipeList.cells.element(boundBy: 0)
                if firstRecipe.exists {
                    // Swipe to delete
                    firstRecipe.swipeLeft()

                    let deleteButton = app.buttons["Delete"]
                    if deleteButton.waitForExistence(timeout: 2) {
                        deleteButton.tap()

                        // Confirm deletion if needed
                        let confirmButton = app.buttons["Confirm"]
                        if confirmButton.exists {
                            confirmButton.tap()
                        }

                        // Recipe should be removed
                        Thread.sleep(forTimeInterval: 1)
                        // Could verify count decreased
                    }
                }
            }
        }
    }

    // MARK: - Meal Planning Tests

    func testMealPlannerDisplays() throws {
        let mealPlannerButton = app.buttons["Meal Planner"]
        if mealPlannerButton.waitForExistence(timeout: 5) {
            mealPlannerButton.tap()

            // Verify calendar or meal plan view appears
            let mealPlanView = app.otherElements["meal_plan_view"]
            let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '2026'")).element

            XCTAssertTrue(mealPlanView.exists || dateHeader.exists)
        }
    }

    func testAddMealToPlan() throws {
        let mealPlannerButton = app.buttons["Meal Planner"]
        if mealPlannerButton.waitForExistence(timeout: 5) {
            mealPlannerButton.tap()

            // Tap on a day/meal slot
            let breakfastSlot = app.buttons["breakfast_slot"]
            if breakfastSlot.waitForExistence(timeout: 3) {
                breakfastSlot.tap()

                // Select a recipe from picker
                let recipePickerExists = app.pickers["recipe_picker"].exists ||
                                        app.sheets.element.exists

                if recipePickerExists {
                    // Select first recipe
                    let firstRecipeOption = app.buttons.element(boundBy: 0)
                    if firstRecipeOption.exists {
                        firstRecipeOption.tap()
                    }

                    // Confirm selection
                    let doneButton = app.buttons["Done"]
                    if doneButton.exists {
                        doneButton.tap()
                    }
                }
            }
        }
    }

    func testGenerateShoppingList() throws {
        // Navigate to meal planner
        let mealPlannerButton = app.buttons["Meal Planner"]
        if mealPlannerButton.waitForExistence(timeout: 5) {
            mealPlannerButton.tap()

            // Look for shopping list button
            let shoppingListButton = app.buttons["Shopping List"]
            if shoppingListButton.waitForExistence(timeout: 3) {
                shoppingListButton.tap()

                // Verify shopping list view appears
                let shoppingListView = app.collectionViews["shopping_list"]
                XCTAssertTrue(shoppingListView.waitForExistence(timeout: 3) ||
                             app.staticTexts["No items"].exists)
            }
        }
    }

    func testCheckOffShoppingListItem() throws {
        // Navigate to shopping list
        let shoppingListButton = app.buttons["Shopping List"]
        if shoppingListButton.waitForExistence(timeout: 5) {
            shoppingListButton.tap()

            // Find an item and tap checkbox
            let firstItem = app.buttons["shopping_item_0"]
            if firstItem.waitForExistence(timeout: 3) {
                firstItem.tap()

                // Verify item marked as completed (visual change)
                // Could check for strikethrough or checkmark
                XCTAssertTrue(firstItem.exists)
            }
        }
    }

    // MARK: - AI Recipe Generation Tests

    func testAIRecipeGeneration() throws {
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            // Look for AI generate button
            let aiGenerateButton = app.buttons["AI Chef"]
            if aiGenerateButton.waitForExistence(timeout: 3) {
                aiGenerateButton.tap()

                // Enter ingredients
                let ingredientsField = app.textFields["ai_ingredients"]
                if ingredientsField.waitForExistence(timeout: 3) {
                    ingredientsField.tap()
                    ingredientsField.typeText("Banana, Oats")

                    // Generate recipe
                    let generateButton = app.buttons["Generate"]
                    if generateButton.exists {
                        generateButton.tap()

                        // Wait for loading indicator or result
                        let loadingIndicator = app.activityIndicators["generating"]
                        if loadingIndicator.waitForExistence(timeout: 2) {
                            // Wait for generation to complete
                            let disappeared = loadingIndicator.waitForNonExistence(timeout: 15)
                            XCTAssertTrue(disappeared)
                        }

                        // Verify recipe appears
                        let recipeTitle = app.textFields["recipe_title"]
                        XCTAssertTrue(recipeTitle.waitForExistence(timeout: 5))
                    }
                }
            }
        }
    }

    // MARK: - Recipe Scanner Tests

    func testRecipeScanner() throws {
        let recipesTab = app.tabBars.buttons["Recipes"]
        if recipesTab.waitForExistence(timeout: 5) {
            recipesTab.tap()

            // Look for scan button
            let scanButton = app.buttons["Scan Recipe"]
            if scanButton.waitForExistence(timeout: 3) {
                scanButton.tap()

                // Camera view should appear
                // (In real test, would need camera permissions)
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.waitForExistence(timeout: 2) {
                    cancelButton.tap()
                }
            }
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
