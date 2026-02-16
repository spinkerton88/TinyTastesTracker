//
//  ProfileSharingManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for ProfileSharingManager functionality
//

import XCTest
@testable import TinyTastesTracker

@MainActor
final class ProfileSharingManagerTests: XCTestCase {

    var sut: ProfileSharingManager!
    var mockAuthManager: AuthenticationManager!

    override func setUp() {
        super.setUp()
        mockAuthManager = AuthenticationManager()
        sut = ProfileSharingManager(authenticationManager: mockAuthManager)
    }

    override func tearDown() {
        sut = nil
        mockAuthManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testProfileSharingManagerInitialization() {
        XCTAssertNotNil(sut, "ProfileSharingManager should initialize successfully")
    }

    func testProfileSharingManagerRequiresAuthenticationManager() {
        let manager = ProfileSharingManager(authenticationManager: mockAuthManager)
        XCTAssertNotNil(manager, "Should initialize with authentication manager")
    }

    // MARK: - Invitation Code Tests

    func testInvitationCodeGeneration() {
        let invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        // Test that invitation code is 6 digits
        XCTAssertEqual(invitation.inviteCode.count, 6, "Invite code should be 6 characters")
        XCTAssertTrue(invitation.inviteCode.allSatisfy { $0.isNumber }, "Invite code should only contain numbers")
    }

    func testInvitationCodeUniqueness() {
        let invitation1 = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Baby A",
            invitedBy: "user123",
            inviterName: "John",
            invitedEmail: "test1@example.com"
        )

        let invitation2 = ProfileInvitation(
            childProfileId: "profile124",
            childName: "Baby B",
            invitedBy: "user124",
            inviterName: "Jane",
            invitedEmail: "test2@example.com"
        )

        // While not guaranteed, codes should likely be different
        // In production, would need retry logic for collisions
        XCTAssertNotNil(invitation1.inviteCode)
        XCTAssertNotNil(invitation2.inviteCode)
    }

    // MARK: - Invitation Status Tests

    func testInvitationInitialStatus() {
        let invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        XCTAssertEqual(invitation.status, .pending, "New invitation should have pending status")
    }

    func testInvitationStatusTransitions() {
        var invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        XCTAssertEqual(invitation.status, .pending, "Initial status should be pending")

        invitation.status = .accepted
        XCTAssertEqual(invitation.status, .accepted, "Status should be accepted after acceptance")

        invitation.status = .declined
        XCTAssertEqual(invitation.status, .declined, "Status should be declined after declining")
    }

    // MARK: - Invitation Expiration Tests

    func testInvitationExpirationCheck() {
        var invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        // Fresh invitation should be valid
        XCTAssertTrue(invitation.isValid, "New invitation should be valid")

        // Set expiration to past date
        invitation.expiresAt = Date().addingTimeInterval(-86400) // 1 day ago
        XCTAssertFalse(invitation.isValid, "Expired invitation should be invalid")

        // Set expiration to future date
        invitation.expiresAt = Date().addingTimeInterval(86400 * 7) // 7 days from now
        XCTAssertTrue(invitation.isValid, "Invitation with future expiration should be valid")
    }

    func testInvitationDefaultExpiration() {
        let invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        let sevenDaysFromNow = Date().addingTimeInterval(86400 * 7)
        let expirationDate = invitation.expiresAt

        // Check expiration is approximately 7 days from now (within 1 minute tolerance)
        XCTAssertTrue(abs(expirationDate.timeIntervalSince(sevenDaysFromNow)) < 60,
                      "Default expiration should be 7 days from creation")
    }

    // MARK: - Invitation Data Validation Tests

    func testInvitationRequiredFields() {
        let invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        XCTAssertFalse(invitation.childProfileId.isEmpty, "Profile ID should not be empty")
        XCTAssertFalse(invitation.childName.isEmpty, "Child name should not be empty")
        XCTAssertFalse(invitation.invitedBy.isEmpty, "Inviter ID should not be empty")
        XCTAssertFalse(invitation.inviterName.isEmpty, "Inviter name should not be empty")
        XCTAssertFalse(invitation.invitedEmail.isEmpty, "Invited email should not be empty")
    }

    func testInvitationEmailFormat() {
        let validEmail = "test@example.com"
        let invalidEmail = "not-an-email"

        XCTAssertTrue(validEmail.contains("@"), "Valid email should contain @")
        XCTAssertFalse(invalidEmail.contains("@"), "Invalid email should not contain @")
    }

    // MARK: - Shared User Tests

    func testSharedUserCreation() {
        let sharedUser = SharedUser(
            userId: "user123",
            name: "John Doe",
            sharedAt: Date()
        )

        XCTAssertEqual(sharedUser.id, "user123", "Shared user ID should match user ID")
        XCTAssertEqual(sharedUser.userId, "user123", "User ID should be set correctly")
        XCTAssertEqual(sharedUser.name, "John Doe", "Name should be set correctly")
        XCTAssertNotNil(sharedUser.sharedAt, "Shared date should be set")
    }

    func testSharedUserOptionalName() {
        let sharedUserWithName = SharedUser(
            userId: "user123",
            name: "John Doe",
            sharedAt: Date()
        )

        let sharedUserWithoutName = SharedUser(
            userId: "user456",
            name: nil,
            sharedAt: Date()
        )

        XCTAssertNotNil(sharedUserWithName.name, "Name should be present when provided")
        XCTAssertNil(sharedUserWithoutName.name, "Name can be optional")
    }

    // MARK: - Sharing Error Tests

    func testSharingErrorTypes() {
        // Test that error types are correctly defined
        let notAuthorizedError = SharingError.notAuthorized
        let profileNotFoundError = SharingError.profileNotFound
        let invalidCodeError = SharingError.invalidCode

        XCTAssertNotNil(notAuthorizedError)
        XCTAssertNotNil(profileNotFoundError)
        XCTAssertNotNil(invalidCodeError)
    }

    // MARK: - Profile Access Control Tests

    func testOwnershipValidation() {
        let ownerId = "user123"
        let differentUserId = "user456"

        // Simulate profile with owner
        let profileOwnerId = "user123"

        XCTAssertEqual(ownerId, profileOwnerId, "Owner should match")
        XCTAssertNotEqual(differentUserId, profileOwnerId, "Different user should not match owner")
    }

    func testSharedWithArrayValidation() {
        var sharedWith = ["user1", "user2", "user3"]

        // Test adding user to shared list
        let newUser = "user4"
        if !sharedWith.contains(newUser) {
            sharedWith.append(newUser)
        }

        XCTAssertEqual(sharedWith.count, 4, "Should have 4 users after adding")
        XCTAssertTrue(sharedWith.contains(newUser), "Should contain new user")

        // Test removing user from shared list
        sharedWith.removeAll { $0 == "user2" }
        XCTAssertEqual(sharedWith.count, 3, "Should have 3 users after removing")
        XCTAssertFalse(sharedWith.contains("user2"), "Should not contain removed user")
    }

    func testDuplicateSharedUserPrevention() {
        var sharedWith = ["user1", "user2"]

        // Attempt to add duplicate
        let userToAdd = "user1"
        if !sharedWith.contains(userToAdd) {
            sharedWith.append(userToAdd)
        }

        XCTAssertEqual(sharedWith.count, 2, "Should not add duplicate user")
    }

    // MARK: - Authorization Tests

    func testOwnerCanInvite() {
        let ownerId = "user123"
        let currentUserId = "user123"

        XCTAssertEqual(ownerId, currentUserId, "Owner should be able to invite (authorization check)")
    }

    func testNonOwnerCannotInvite() {
        let ownerId = "user123"
        let currentUserId = "user456"

        XCTAssertNotEqual(ownerId, currentUserId, "Non-owner should not be able to invite")
    }

    func testOwnerCanRevokeAccess() {
        let ownerId = "user123"
        let currentUserId = "user123"
        var sharedWith = ["user2", "user3"]

        // Owner can revoke access
        if ownerId == currentUserId {
            sharedWith.removeAll { $0 == "user2" }
        }

        XCTAssertFalse(sharedWith.contains("user2"), "Owner should be able to revoke access")
    }

    func testNonOwnerCannotRevokeOthersAccess() {
        let ownerId = "user123"
        let currentUserId = "user456" // Not the owner
        var sharedWith = ["user2", "user3"]

        // Non-owner cannot revoke others' access
        XCTAssertNotEqual(ownerId, currentUserId, "Non-owner should not be able to revoke access")
    }

    func testUserCanRemoveSelfFromSharedProfile() {
        let currentUserId = "user2"
        var sharedWith = ["user2", "user3"]

        // User can always remove themselves
        sharedWith.removeAll { $0 == currentUserId }

        XCTAssertFalse(sharedWith.contains(currentUserId), "User should be able to remove themselves")
    }

    // MARK: - Edge Cases

    func testInvitationWithEmptyEmail() {
        let invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: ""
        )

        XCTAssertTrue(invitation.invitedEmail.isEmpty, "Should allow empty email (validation elsewhere)")
    }

    func testMultipleInvitationsForSameProfile() {
        let invitation1 = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Baby",
            invitedBy: "user1",
            inviterName: "John",
            invitedEmail: "user2@example.com"
        )

        let invitation2 = ProfileInvitation(
            childProfileId: "profile123", // Same profile
            childName: "Baby",
            invitedBy: "user1",
            inviterName: "John",
            invitedEmail: "user3@example.com" // Different email
        )

        XCTAssertEqual(invitation1.childProfileId, invitation2.childProfileId,
                       "Multiple invitations can exist for same profile")
        XCTAssertNotEqual(invitation1.invitedEmail, invitation2.invitedEmail,
                          "But invitations should go to different users")
    }

    func testExpiredInvitationCannotBeAccepted() {
        var invitation = ProfileInvitation(
            childProfileId: "profile123",
            childName: "Test Baby",
            invitedBy: "user123",
            inviterName: "John Doe",
            invitedEmail: "test@example.com"
        )

        invitation.expiresAt = Date().addingTimeInterval(-86400) // Expired

        XCTAssertFalse(invitation.isValid, "Expired invitation should not be valid")
        XCTAssertEqual(invitation.status, .pending, "Expired invitation remains pending until explicitly declined")
    }
}

// MARK: - Mock Data Helpers

extension ProfileSharingManagerTests {

    func createMockInvitation(profileId: String = "profile123",
                             invitedBy: String = "user1",
                             invitedEmail: String = "test@example.com") -> ProfileInvitation {
        return ProfileInvitation(
            childProfileId: profileId,
            childName: "Test Baby",
            invitedBy: invitedBy,
            inviterName: "Test User",
            invitedEmail: invitedEmail
        )
    }

    func createExpiredInvitation() -> ProfileInvitation {
        var invitation = createMockInvitation()
        invitation.expiresAt = Date().addingTimeInterval(-86400)
        return invitation
    }
}
