//
//  UserProfileTests.swift
//  TinyTastesTrackerTests
//
//  Tests for UserProfile model
//

import XCTest
@testable import TinyTastesTracker

final class UserProfileTests: XCTestCase {
    
    func testProfileCreation() {
        let birthDate = Date()
        let profile = UserProfile(
            babyName: "Test Baby",
            birthDate: birthDate,
            gender: .boy
        )
        
        XCTAssertEqual(profile.babyName, "Test Baby")
        XCTAssertEqual(profile.birthDate, birthDate)
        XCTAssertEqual(profile.gender, .boy)
    }
    
    func testProfileWithAllergies() {
        let profile = UserProfile(
            babyName: "Test Baby",
            birthDate: Date(),
            gender: .girl,
            knownAllergies: ["Peanuts", "Dairy"]
        )
        
        XCTAssertEqual(profile.knownAllergies, ["Peanuts", "Dairy"])
    }
    
    func testGenderOptions() {
        let boyProfile = UserProfile(babyName: "Boy", birthDate: Date(), gender: .boy)
        let girlProfile = UserProfile(babyName: "Girl", birthDate: Date(), gender: .girl)
        let otherProfile = UserProfile(babyName: "Other", birthDate: Date(), gender: .other)
        
        XCTAssertEqual(boyProfile.gender, .boy)
        XCTAssertEqual(girlProfile.gender, .girl)
        XCTAssertEqual(otherProfile.gender, .other)
    }
    
    func testAgeInMonthsForNewborn() {
        let birthDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let profile = UserProfile(babyName: "Newborn", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.ageInMonths, 0)
    }
    
    func testAgeInMonthsForSixMonthOld() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let profile = UserProfile(babyName: "Six Month Old", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.ageInMonths, 6)
    }
    
    func testAgeInMonthsForOneYearOld() {
        let birthDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let profile = UserProfile(babyName: "One Year Old", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.ageInMonths, 12)
    }
    
    func testCurrentModeForNewborn() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let profile = UserProfile(babyName: "Test", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.currentMode, .newborn)
    }
    
    func testCurrentModeForExplorer() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
        let profile = UserProfile(babyName: "Test", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.currentMode, .explorer)
    }
    
    func testCurrentModeForToddler() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -15, to: Date())!
        let profile = UserProfile(babyName: "Test", birthDate: birthDate, gender: .other)
        
        XCTAssertEqual(profile.currentMode, .toddler)
    }
}
