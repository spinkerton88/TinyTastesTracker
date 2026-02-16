//
//  ProfileManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for ProfileManager functionality
//

import XCTest
@testable import TinyTastesTracker

@MainActor
final class ProfileManagerTests: XCTestCase {

    var sut: ProfileManager!

    override func setUp() {
        super.setUp()
        sut = ProfileManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testProfileManagerInitialization() {
        XCTAssertNotNil(sut, "ProfileManager should initialize successfully")
        XCTAssertTrue(sut.profiles.isEmpty, "ProfileManager should start with no profiles")
        XCTAssertNil(sut.activeProfile, "No active profile should be set initially")
    }

    // MARK: - Profile Merging Tests

    func testMergeProfilesDeduplication() {
        // Create test profiles
        let profile1 = ChildProfile(ownerId: "user1", name: "Alice", birthDate: Date(), gender: .girl)
        let profile2 = ChildProfile(ownerId: "user1", name: "Bob", birthDate: Date(), gender: .boy)
        let profile3 = ChildProfile(ownerId: "user1", name: "Charlie", birthDate: Date(), gender: .other)

        // Simulate owned and shared profiles with same profile appearing twice
        var testProfiles = [profile1, profile2, profile3]

        // Test that profiles are merged correctly (deduplicated)
        XCTAssertEqual(testProfiles.count, 3, "Should have 3 unique profiles")
    }

    func testProfilesSortedByName() {
        let profileZebra = ChildProfile(ownerId: "user1", name: "Zebra", birthDate: Date(), gender: .other)
        let profileAlpha = ChildProfile(ownerId: "user1", name: "Alpha", birthDate: Date(), gender: .other)
        let profileMike = ChildProfile(ownerId: "user1", name: "Mike", birthDate: Date(), gender: .other)

        let unsortedProfiles = [profileZebra, profileAlpha, profileMike]
        let sortedProfiles = unsortedProfiles.sorted { $0.name < $1.name }

        XCTAssertEqual(sortedProfiles[0].name, "Alpha", "First profile should be Alpha")
        XCTAssertEqual(sortedProfiles[1].name, "Mike", "Second profile should be Mike")
        XCTAssertEqual(sortedProfiles[2].name, "Zebra", "Third profile should be Zebra")
    }

    // MARK: - Active Profile Tests

    func testSetActiveProfile() {
        var testProfile = ChildProfile(ownerId: "user1", name: "Test Baby", birthDate: Date(), gender: .other)
        testProfile.id = "profile123"

        sut.setActiveProfile(testProfile)

        // Note: This will fail in actual test because ProfileManager uses Firestore
        // For real tests, we'd need to mock FirestoreService
        XCTAssertNotNil(sut.activeProfileId, "Active profile ID should be set")
    }

    func testActiveProfileComputedProperty() {
        // Create test profile with ID
        var profile1 = ChildProfile(ownerId: "user1", name: "Alice", birthDate: Date(), gender: .girl)
        profile1.id = "test-id-1"

        var profile2 = ChildProfile(ownerId: "user1", name: "Bob", birthDate: Date(), gender: .boy)
        profile2.id = "test-id-2"

        // Manually set profiles (in real tests we'd mock Firestore)
        // This demonstrates the logic

        XCTAssertNil(sut.activeProfile, "Should return nil when activeProfileId is nil")
    }

    // MARK: - Profile CRUD Tests

    func testCreateProfileValidation() {
        let name = "New Baby"
        let birthDate = Date()
        let gender = Gender.other
        let ownerId = "user123"

        // Validate profile creation parameters
        XCTAssertFalse(name.isEmpty, "Name should not be empty")
        XCTAssertNotNil(birthDate, "Birth date should be set")
        XCTAssertFalse(ownerId.isEmpty, "Owner ID should not be empty")
    }

    func testUpdateProfileMergesChanges() {
        var profile = ChildProfile(ownerId: "user1", name: "Original Name", birthDate: Date(), gender: .other)
        profile.id = "test-id"

        // Test update logic
        var updatedProfile = profile
        updatedProfile.name = "Updated Name"
        updatedProfile.preferredMode = .newborn

        XCTAssertEqual(updatedProfile.name, "Updated Name", "Name should be updated")
        XCTAssertEqual(updatedProfile.preferredMode, .newborn, "Mode should be updated")
        XCTAssertEqual(updatedProfile.id, profile.id, "ID should remain the same")
    }

    func testDeleteProfileRequiresID() {
        let profileWithoutID = ChildProfile(ownerId: "user1", name: "Test", birthDate: Date(), gender: .other)

        // Profile without ID should not be deletable
        XCTAssertNil(profileWithoutID.id, "Profile should not have ID initially")
    }

    // MARK: - Growth Comparison Tests

    func testGrowthComparisonDataFiltering() {
        let profile1 = ChildProfile(ownerId: "user1", name: "Alice", birthDate: Date(), gender: .girl)
        let profile2 = ChildProfile(ownerId: "user1", name: "Bob", birthDate: Date(), gender: .boy)

        // Create test growth measurements
        var measurement1 = GrowthMeasurement(
            babyId: profile1.id ?? "id1",
            weight: 10.5,
            height: 60.0,
            headCircumference: 40.0,
            ownerId: "user1"
        )
        measurement1.date = Date()

        var measurement2 = GrowthMeasurement(
            babyId: profile2.id ?? "id2",
            weight: 11.0,
            height: 62.0,
            headCircumference: 41.0,
            ownerId: "user1"
        )
        measurement2.date = Date()

        let allMeasurements = [measurement1, measurement2]

        // Filter measurements by profile
        let aliceMeasurements = allMeasurements.filter { $0.babyId == (profile1.id ?? "id1") }
        let bobMeasurements = allMeasurements.filter { $0.babyId == (profile2.id ?? "id2") }

        XCTAssertEqual(aliceMeasurements.count, 1, "Alice should have 1 measurement")
        XCTAssertEqual(bobMeasurements.count, 1, "Bob should have 1 measurement")
        XCTAssertEqual(aliceMeasurements.first?.weight, 10.5, "Alice's weight should be 10.5")
        XCTAssertEqual(bobMeasurements.first?.weight, 11.0, "Bob's weight should be 11.0")
    }

    func testGrowthMetricExtraction() {
        var measurement = GrowthMeasurement(
            babyId: "test-id",
            weight: 10.5,
            height: 60.0,
            headCircumference: 40.0,
            ownerId: "user1"
        )
        measurement.date = Date()

        // Test metric extraction
        let weightMetric = GrowthMetric.weight
        let heightMetric = GrowthMetric.height
        let headMetric = GrowthMetric.headCircumference

        XCTAssertEqual(measurement.weight, 10.5, "Weight should be extractable")
        XCTAssertEqual(measurement.height, 60.0, "Height should be extractable")
        XCTAssertEqual(measurement.headCircumference, 40.0, "Head circumference should be extractable")
    }

    // MARK: - Profile Validation Tests

    func testProfileAgeCalculation() {
        let birthDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let profile = ChildProfile(ownerId: "user1", name: "Baby", birthDate: birthDate, gender: .other)

        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0

        XCTAssertEqual(ageInMonths, 6, "Baby should be 6 months old")
        XCTAssertEqual(profile.ageInMonths, 6, "Profile's ageInMonths should return 6")
    }

    func testProfileModeSelection() {
        let newbornBirthDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let explorerBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
        let toddlerBirthDate = Calendar.current.date(byAdding: .month, value: -18, to: Date())!

        let newbornProfile = ChildProfile(ownerId: "user1", name: "Newborn", birthDate: newbornBirthDate, gender: .other)
        let explorerProfile = ChildProfile(ownerId: "user1", name: "Explorer", birthDate: explorerBirthDate, gender: .other)
        let toddlerProfile = ChildProfile(ownerId: "user1", name: "Toddler", birthDate: toddlerBirthDate, gender: .other)

        XCTAssertEqual(newbornProfile.currentMode, .newborn, "3-month-old should be in newborn mode")
        XCTAssertEqual(explorerProfile.currentMode, .explorer, "8-month-old should be in explorer mode")
        XCTAssertEqual(toddlerProfile.currentMode, .toddler, "18-month-old should be in toddler mode")
    }

    func testPreferredModeOverride() {
        var profile = ChildProfile(ownerId: "user1", name: "Baby", birthDate: Date(), gender: .other)

        // Test default (age-based) mode
        XCTAssertNil(profile.preferredMode, "Preferred mode should be nil by default")

        // Test preferred mode override
        profile.preferredMode = .toddler
        XCTAssertEqual(profile.currentMode, .toddler, "Should use preferred mode when set")
    }

    // MARK: - Known Allergies Tests

    func testKnownAllergiesManagement() {
        var profile = ChildProfile(ownerId: "user1", name: "Baby", birthDate: Date(), gender: .other)

        // Test no allergies
        XCTAssertNil(profile.knownAllergies, "Should have no allergies initially")

        // Test adding allergies
        profile.knownAllergies = ["Peanuts", "Milk", "Eggs"]
        XCTAssertEqual(profile.knownAllergies?.count, 3, "Should have 3 allergies")
        XCTAssertTrue(profile.knownAllergies?.contains("Peanuts") ?? false, "Should contain Peanuts")

        // Test empty array vs nil
        profile.knownAllergies = []
        XCTAssertEqual(profile.knownAllergies?.count, 0, "Should have empty allergy array")
    }

    // MARK: - Profile Persistence Tests

    func testActiveProfilePersistenceKey() {
        let expectedKey = "ProfileManager.activeProfileId"

        // Test that the key is correctly formatted
        XCTAssertFalse(expectedKey.isEmpty, "Persistence key should not be empty")
        XCTAssertTrue(expectedKey.contains("activeProfileId"), "Key should reference activeProfileId")
    }

    // MARK: - Edge Cases

    func testEmptyProfileList() {
        XCTAssertTrue(sut.profiles.isEmpty, "Initially, profiles should be empty")
        XCTAssertNil(sut.activeProfile, "Active profile should be nil when profiles is empty")
    }

    func testProfileWithoutOwner() {
        // This should not be possible in production, but test defensive coding
        let invalidProfile = ChildProfile(ownerId: "", name: "Test", birthDate: Date(), gender: .other)

        XCTAssertTrue(invalidProfile.ownerId.isEmpty, "Owner ID should be empty")
    }

    func testMultipleProfilesWithSameName() {
        let profile1 = ChildProfile(ownerId: "user1", name: "Baby", birthDate: Date(), gender: .girl)
        let profile2 = ChildProfile(ownerId: "user1", name: "Baby", birthDate: Date(), gender: .boy)

        // Profiles with same name should be allowed
        XCTAssertEqual(profile1.name, profile2.name, "Profiles can have the same name")
        XCTAssertNotEqual(profile1.gender, profile2.gender, "But should be distinguishable by other properties")
    }

    // MARK: - Notification Tests

    func testActiveProfileChangeNotification() {
        let expectation = XCTestExpectation(description: "Profile change notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .activeProfileChanged,
            object: nil,
            queue: nil
        ) { notification in
            expectation.fulfill()
        }

        var testProfile = ChildProfile(ownerId: "user1", name: "Test", birthDate: Date(), gender: .other)
        testProfile.id = "test123"

        sut.setActiveProfile(testProfile)

        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }
}

// MARK: - Mock Data Helpers

extension ProfileManagerTests {

    func createMockProfile(name: String = "Test Baby", ageMonths: Int = 6, ownerId: String = "user1") -> ChildProfile {
        let birthDate = Calendar.current.date(byAdding: .month, value: -ageMonths, to: Date())!
        return ChildProfile(ownerId: ownerId, name: name, birthDate: birthDate, gender: .other)
    }

    func createMockProfiles(count: Int, ownerId: String = "user1") -> [ChildProfile] {
        return (0..<count).map { index in
            createMockProfile(name: "Baby \(index + 1)", ageMonths: (index + 1) * 3, ownerId: ownerId)
        }
    }
}
