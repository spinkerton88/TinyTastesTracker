//
//  ProfileSharingManager.swift
//  TinyTastesTracker
//
//  Manages profile sharing and invitations
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Observation

struct SharedUser: Identifiable {
    var id: String { userId }
    var userId: String
    var name: String?
    var sharedAt: Date
}

@Observable
class ProfileSharingManager {
    private let db = Firestore.firestore()
    private let invitationService = FirestoreService<ProfileInvitation>(collectionName: "profile_invitations")
    private let profileService = FirestoreService<ChildProfile>(collectionName: "child_profiles")
    private let authenticationManager: AuthenticationManager

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
    }

    // MARK: - Create Invitation

    /// Create an invitation to share a profile
    func createInvitation(childProfileId: String, invitedEmail: String, currentUserId: String) async throws -> ProfileInvitation {
        // Load the child profile to get details
        guard let profile = try? await profileService.getDocument(id: childProfileId) else {
            throw SharingError.profileNotFound
        }

        // Ensure current user is the owner
        guard profile.ownerId == currentUserId else {
            throw SharingError.notAuthorized
        }

        // Get current user's name (from auth or user profile)
        let inviterName = await MainActor.run {
            authenticationManager.userSession?.displayName ??
            authenticationManager.userSession?.email?.components(separatedBy: "@").first ??
            "Someone"
        }

        // Create the invitation
        let invitation = ProfileInvitation(
            childProfileId: childProfileId,
            childName: profile.name,
            invitedBy: currentUserId,
            inviterName: inviterName,
            invitedEmail: invitedEmail
        )

        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            // Invitations require network connectivity - cannot be queued offline
            throw FirebaseError.networkUnavailable
        }

        // Save to Firestore with retry
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                try await self.invitationService.add(invitation)
            }
        }

        return invitation
    }

    // MARK: - Accept Invitation

    /// Accept an invitation using the 6-digit code
    func acceptInvitation(inviteCode: String, userId: String) async throws {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw FirebaseError.networkUnavailable
        }

        // Find invitation by code (query by inviteCode field)
        let snapshot = try await db.collection("profile_invitations")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()

        guard let invitationDoc = snapshot.documents.first,
              let invitation = try? invitationDoc.data(as: ProfileInvitation.self) else {
            throw SharingError.invalidCode
        }

        // Check if invitation is still valid
        // TEMPORARILY DISABLED FOR TESTING
        // TODO: Re-enable validation after testing complete
        // guard invitation.isValid else {
        //     throw SharingError.invitationExpired
        // }

        // Store original state for rollback
        let originalInvitation = invitation
        var profileUpdated = false
        var libraryUpdated = false

        do {
            // Update invitation status with retry
            var updatedInvitation = invitation
            updatedInvitation.status = .accepted
            try await withRetry(maxAttempts: 3) {
                try await withTimeout(seconds: 10) {
                    try await self.invitationService.update(updatedInvitation)
                }
            }

            // Add user to profile's sharedWith array
            guard var profile = try? await profileService.getDocument(id: invitation.childProfileId) else {
                throw SharingError.profileNotFound
            }

            if profile.sharedWith == nil {
                profile.sharedWith = []
            }

            if !profile.sharedWith!.contains(userId) {
                profile.sharedWith!.append(userId)
                try await withRetry(maxAttempts: 3) {
                    try await withTimeout(seconds: 10) {
                        try await self.profileService.update(profile)
                    }
                }
                profileUpdated = true
            }

            // Sync recipe/food/shopping library access
            try await syncLibraryAccess(ownerUserId: invitation.invitedBy, sharedUserId: userId, isAdding: true)
            libraryUpdated = true
            
        } catch {
            // Rollback on failure
            print("⚠️ Accepting invitation failed, rolling back...")
            
            if libraryUpdated {
                try? await syncLibraryAccess(ownerUserId: invitation.invitedBy, sharedUserId: userId, isAdding: false)
            }
            
            if profileUpdated {
                if var profile = try? await profileService.getDocument(id: invitation.childProfileId) {
                    profile.sharedWith?.removeAll { $0 == userId }
                    try? await profileService.update(profile)
                }
            }
            
            // Revert invitation status
            try? await invitationService.update(originalInvitation)
            
            throw FirebaseError.from(error)
        }
    }

    // MARK: - Sync Library Access

    /// Sync recipe, custom food, and shopping list access between users
    private func syncLibraryAccess(ownerUserId: String, sharedUserId: String, isAdding: Bool) async throws {
        // Track which operations succeeded for rollback
        var completedOperations: [(collection: String, ownerId: String, userId: String)] = []
        
        do {
            // Bidirectional sharing: both users get access to each other's libraries
            if isAdding {
                // Add shared user to owner's items
                try await addToSharedWith(collection: "recipes", ownerId: ownerUserId, userId: sharedUserId)
                completedOperations.append(("recipes", ownerUserId, sharedUserId))
                
                try await addToSharedWith(collection: "custom_foods", ownerId: ownerUserId, userId: sharedUserId)
                completedOperations.append(("custom_foods", ownerUserId, sharedUserId))
                
                try await addToSharedWith(collection: "shopping_list_items", ownerId: ownerUserId, userId: sharedUserId)
                completedOperations.append(("shopping_list_items", ownerUserId, sharedUserId))

                // Add owner to shared user's items
                try await addToSharedWith(collection: "recipes", ownerId: sharedUserId, userId: ownerUserId)
                completedOperations.append(("recipes", sharedUserId, ownerUserId))
                
                try await addToSharedWith(collection: "custom_foods", ownerId: sharedUserId, userId: ownerUserId)
                completedOperations.append(("custom_foods", sharedUserId, ownerUserId))
                
                try await addToSharedWith(collection: "shopping_list_items", ownerId: sharedUserId, userId: ownerUserId)
                completedOperations.append(("shopping_list_items", sharedUserId, ownerUserId))
            } else {
                // Check if users still share any other profiles
                let stillSharing = try await checkIfUsersStillShareProfiles(user1: ownerUserId, user2: sharedUserId)

                if !stillSharing {
                    // Remove shared user from owner's items
                    try await removeFromSharedWith(collection: "recipes", ownerId: ownerUserId, userId: sharedUserId)
                    try await removeFromSharedWith(collection: "custom_foods", ownerId: ownerUserId, userId: sharedUserId)
                    try await removeFromSharedWith(collection: "shopping_list_items", ownerId: ownerUserId, userId: sharedUserId)

                    // Remove owner from shared user's items
                    try await removeFromSharedWith(collection: "recipes", ownerId: sharedUserId, userId: ownerUserId)
                    try await removeFromSharedWith(collection: "custom_foods", ownerId: sharedUserId, userId: ownerUserId)
                    try await removeFromSharedWith(collection: "shopping_list_items", ownerId: sharedUserId, userId: ownerUserId)
                }
            }
        } catch {
            // Rollback completed operations
            print("⚠️ Library sync failed, rolling back \(completedOperations.count) operations...")
            for operation in completedOperations.reversed() {
                try? await removeFromSharedWith(
                    collection: operation.collection,
                    ownerId: operation.ownerId,
                    userId: operation.userId
                )
            }
            throw error
        }
    }

    /// Add userId to sharedWith array for all items in collection owned by ownerId
    private func addToSharedWith(collection: String, ownerId: String, userId: String) async throws {
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 15) {
                let snapshot = try await self.db.collection(collection)
                    .whereField("ownerId", isEqualTo: ownerId)
                    .getDocuments()

                for document in snapshot.documents {
                    try await document.reference.updateData([
                        "sharedWith": FieldValue.arrayUnion([userId])
                    ])
                }
            }
        }
    }

    /// Remove userId from sharedWith array for all items in collection owned by ownerId
    private func removeFromSharedWith(collection: String, ownerId: String, userId: String) async throws {
        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 15) {
                let snapshot = try await self.db.collection(collection)
                    .whereField("ownerId", isEqualTo: ownerId)
                    .getDocuments()

                for document in snapshot.documents {
                    try await document.reference.updateData([
                        "sharedWith": FieldValue.arrayRemove([userId])
                    ])
                }
            }
        }
    }

    /// Check if two users share any profiles together
    private func checkIfUsersStillShareProfiles(user1: String, user2: String) async throws -> Bool {
        // Get all profiles owned by user1
        let user1Profiles = try await db.collection("child_profiles")
            .whereField("ownerId", isEqualTo: user1)
            .getDocuments()

        // Check if user2 is in any sharedWith arrays
        for doc in user1Profiles.documents {
            if let sharedWith = doc.data()["sharedWith"] as? [String],
               sharedWith.contains(user2) {
                return true
            }
        }

        // Get all profiles owned by user2
        let user2Profiles = try await db.collection("child_profiles")
            .whereField("ownerId", isEqualTo: user2)
            .getDocuments()

        // Check if user1 is in any sharedWith arrays
        for doc in user2Profiles.documents {
            if let sharedWith = doc.data()["sharedWith"] as? [String],
               sharedWith.contains(user1) {
                return true
            }
        }

        return false
    }

    // MARK: - Decline Invitation

    /// Decline an invitation
    func declineInvitation(invitationId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw FirebaseError.networkUnavailable
        }

        guard var invitation = try? await invitationService.getDocument(id: invitationId) else {
            throw SharingError.invitationNotFound
        }

        invitation.status = .declined

        try await withRetry(maxAttempts: 3) {
            try await withTimeout(seconds: 10) {
                try await self.invitationService.update(invitation)
            }
        }
    }

    // MARK: - Revoke Access

    /// Revoke a user's access to a profile (owner only)
    func revokeAccess(childProfileId: String, userId: String, currentUserId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw FirebaseError.networkUnavailable
        }

        guard var profile = try? await profileService.getDocument(id: childProfileId) else {
            throw SharingError.profileNotFound
        }

        // Ensure current user is the owner
        guard profile.ownerId == currentUserId else {
            throw SharingError.notAuthorized
        }

        // Cannot revoke owner's access
        guard userId != profile.ownerId else {
            throw SharingError.cannotRevokeOwner
        }

        // Store original state for rollback
        let originalSharedWith = profile.sharedWith
        var profileUpdated = false

        do {
            // Remove user from sharedWith array
            if var sharedWith = profile.sharedWith {
                sharedWith.removeAll { $0 == userId }
                profile.sharedWith = sharedWith.isEmpty ? nil : sharedWith

                try await withRetry(maxAttempts: 3) {
                    try await withTimeout(seconds: 10) {
                        try await self.profileService.update(profile)
                    }
                }
                profileUpdated = true
            }

            // Sync recipe/food/shopping library access
            try await syncLibraryAccess(ownerUserId: currentUserId, sharedUserId: userId, isAdding: false)
            
        } catch {
            // Rollback on failure
            if profileUpdated {
                profile.sharedWith = originalSharedWith
                try? await profileService.update(profile)
            }
            throw FirebaseError.from(error)
        }
    }

    // MARK: - Remove Self

    /// Allow a shared user to remove themselves from a profile
    func removeSelfFromProfile(childProfileId: String, userId: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw FirebaseError.networkUnavailable
        }

        guard var profile = try? await profileService.getDocument(id: childProfileId) else {
            throw SharingError.profileNotFound
        }

        // Cannot remove if you're the owner
        guard userId != profile.ownerId else {
            throw SharingError.ownerCannotLeave
        }

        // Store original state for rollback
        let originalSharedWith = profile.sharedWith
        let ownerId = profile.ownerId
        var profileUpdated = false

        do {
            // Remove self from sharedWith array
            if var sharedWith = profile.sharedWith {
                sharedWith.removeAll { $0 == userId }
                profile.sharedWith = sharedWith.isEmpty ? nil : sharedWith

                try await withRetry(maxAttempts: 3) {
                    try await withTimeout(seconds: 10) {
                        try await self.profileService.update(profile)
                    }
                }
                profileUpdated = true
            }

            // Sync recipe/food/shopping library access
            try await syncLibraryAccess(ownerUserId: ownerId, sharedUserId: userId, isAdding: false)
            
        } catch {
            // Rollback on failure
            if profileUpdated {
                profile.sharedWith = originalSharedWith
                try? await profileService.update(profile)
            }
            throw FirebaseError.from(error)
        }
    }

    // MARK: - Load Invitations

    /// Load all invitations sent by the current user
    func loadSentInvitations(userId: String) async throws -> [ProfileInvitation] {
        let invitations = try await invitationService.fetch(forUserId: userId)
        return invitations.filter { $0.invitedBy == userId }
            .sorted { $0.invitedAt > $1.invitedAt }
    }

    /// Load all pending invitations for a specific profile
    func loadPendingInvitations(forProfile profileId: String) async throws -> [ProfileInvitation] {
        let allInvitations = try await loadAllInvitations()
        return allInvitations.filter {
            $0.childProfileId == profileId && $0.status == .pending
        }
    }

    /// Load all invitations (helper method)
    private func loadAllInvitations() async throws -> [ProfileInvitation] {
        // This is inefficient - in production, we'd add proper indexes and queries
        // For now, this works for a small number of invitations
        let snapshot = try await db.collection("profile_invitations").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ProfileInvitation.self) }
    }

    // MARK: - Load Shared Users

    /// Load list of users who have access to a profile
    func loadSharedUsers(forProfile profileId: String) async throws -> [SharedUser] {
        guard let profile = try? await profileService.getDocument(id: profileId) else {
            throw SharingError.profileNotFound
        }

        guard let sharedWith = profile.sharedWith, !sharedWith.isEmpty else {
            return []
        }

        // In a real app, we'd fetch user details from a users collection
        // For now, return basic info with placeholder data
        return sharedWith.map { userId in
            SharedUser(
                userId: userId,
                name: nil,
                sharedAt: Date() // TODO: Track actual share date
            )
        }
    }

    /// Load invitations for a specific email address
    func loadInvitations(forEmail email: String) async throws -> [ProfileInvitation] {
        let snapshot = try await db.collection("profile_invitations")
            .whereField("invitedEmail", isEqualTo: email)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ProfileInvitation.self) }
    }
}

// MARK: - Errors

enum SharingError: LocalizedError {
    case profileNotFound
    case notAuthorized
    case alreadyShared
    case invitationPending
    case invalidCode
    case invitationExpired
    case invitationNotFound
    case cannotRevokeOwner
    case ownerCannotLeave

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Profile not found"
        case .notAuthorized:
            return "You don't have permission to share this profile"
        case .alreadyShared:
            return "This person already has access to this profile"
        case .invitationPending:
            return "An invitation is already pending"
        case .invalidCode:
            return "Invalid invitation code. Please check and try again."
        case .invitationExpired:
            return "This invitation has expired"
        case .invitationNotFound:
            return "Invitation not found"
        case .cannotRevokeOwner:
            return "Cannot revoke the owner's access"
        case .ownerCannotLeave:
            return "As the owner, you cannot remove yourself from the profile"
        }
    }
}
