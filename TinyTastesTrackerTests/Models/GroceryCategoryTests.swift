//
//  GroceryCategoryTests.swift
//  TinyTastesTrackerTests
//
//  Tests for GroceryCategory enum
//

import XCTest
@testable import TinyTastesTracker

final class GroceryCategoryTests: XCTestCase {
    
    func testAllCategoriesHaveIcons() {
        let categories: [GroceryCategory] = [.produce, .dairy, .meatSeafood, .pantry, .frozen, .bakery, .beverages, .other]
        
        for category in categories {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }
    
    func testProduceCategoryIcon() {
        XCTAssertEqual(GroceryCategory.produce.icon, "🥬")
    }
    
    func testDairyCategoryIcon() {
        XCTAssertEqual(GroceryCategory.dairy.icon, "🥛")
    }
    
    func testMeatSeafoodCategoryIcon() {
        XCTAssertEqual(GroceryCategory.meatSeafood.icon, "🍖")
    }
    
    func testPantryCategoryIcon() {
        XCTAssertEqual(GroceryCategory.pantry.icon, "🥫")
    }
    
    func testFrozenCategoryIcon() {
        XCTAssertEqual(GroceryCategory.frozen.icon, "🧊")
    }
    
    func testBakeryCategoryIcon() {
        XCTAssertEqual(GroceryCategory.bakery.icon, "🍞")
    }
    
    func testBeveragesCategoryIcon() {
        XCTAssertEqual(GroceryCategory.beverages.icon, "🥤")
    }
    
    func testOtherCategoryIcon() {
        XCTAssertEqual(GroceryCategory.other.icon, "🛒")
    }
}
