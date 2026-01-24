//
//  ShoppingListItemTests.swift
//  TinyTastesTrackerTests
//
//  Tests for ShoppingListItem model
//

import XCTest
@testable import TinyTastesTracker

final class ShoppingListItemTests: XCTestCase {
    
    func testItemCreationWithAllProperties() {
        let item = ShoppingListItem(
            name: "Milk",
            quantity: "1",
            unit: "gallon",
            category: .dairy,
            source: .recipe
        )
        
        XCTAssertEqual(item.name, "Milk")
        XCTAssertEqual(item.quantity, "1")
        XCTAssertEqual(item.unit, "gallon")
        XCTAssertEqual(item.category, .dairy)
        XCTAssertEqual(item.source, .recipe)
        XCTAssertFalse(item.isCompleted)
    }
    
    func testItemCreationWithoutQuantity() {
        let item = ShoppingListItem(
            name: "Salt",
            quantity: nil,
            unit: nil,
            category: .pantry,
            source: .manual
        )
        
        XCTAssertNil(item.quantity)
        XCTAssertNil(item.unit)
        XCTAssertEqual(item.name, "Salt")
        XCTAssertEqual(item.category, .pantry)
    }
    
    func testItemSourceTypes() {
        let recipeItem = ShoppingListItem(name: "Test", source: .recipe)
        let manualItem = ShoppingListItem(name: "Test", source: .manual)
        
        XCTAssertEqual(recipeItem.source, .recipe)
        XCTAssertEqual(manualItem.source, .manual)
    }
    
    func testItemCompletion() {
        let item = ShoppingListItem(name: "Test")
        
        XCTAssertFalse(item.isCompleted)
        
        item.isCompleted = true
        XCTAssertTrue(item.isCompleted)
    }
    
    func testDefaultCategory() {
        let item = ShoppingListItem(name: "Unknown Item")
        
        // Default category should be .other
        XCTAssertEqual(item.category, .other)
    }
    
    func testCategoryAssignment() {
        let produceItem = ShoppingListItem(name: "Apple", category: .produce)
        let dairyItem = ShoppingListItem(name: "Milk", category: .dairy)
        let meatItem = ShoppingListItem(name: "Chicken", category: .meatSeafood)
        
        XCTAssertEqual(produceItem.category, .produce)
        XCTAssertEqual(dairyItem.category, .dairy)
        XCTAssertEqual(meatItem.category, .meatSeafood)
    }
}
