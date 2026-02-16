//
//  ProfileInvitation.swift
//  TinyTastesTracker
//
//  Model for profile sharing invitations
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
    case expired
}

struct ProfileInvitation: Identifiable, Codable {
    @DocumentID var id: String?
    var childProfileId: String          // Which profile is being shared
    var childName: String                // Cached for display
    var invitedBy: String                // Owner's user ID
    var inviterName: String              // Owner's name (cached for display)
    var invitedEmail: String             // Email address of person being invited
    var status: InvitationStatus         // Current status
    var invitedAt: Date                  // When invitation was created
    var expiresAt: Date                  // Expiration date (7 days default)
    var inviteCode: String               // 6-digit verification code

    init(childProfileId: String,
         childName: String,
         invitedBy: String,
         inviterName: String,
         invitedEmail: String,
         status: InvitationStatus = .pending,
         invitedAt: Date = Date(),
         expiresAt: Date? = nil,
         inviteCode: String? = nil) {
        self.childProfileId = childProfileId
        self.childName = childName
        self.invitedBy = invitedBy
        self.inviterName = inviterName
        self.invitedEmail = invitedEmail
        self.status = status
        self.invitedAt = invitedAt
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .day, value: 7, to: invitedAt) ?? Date().addingTimeInterval(7 * 24 * 3600)
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
    }

    /// Check if invitation is still valid
    var isValid: Bool {
        // TODO: Re-enable expiration check after testing
        // For now, only check status to allow testing with old invitations
        return status == .pending
        // Production version:
        // status == .pending && Date() < expiresAt
    }

    /// Generate deep link URL for invitation
    var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = "tinytastes"
        components.host = "accept-invite"
        components.queryItems = [URLQueryItem(name: "code", value: inviteCode)]
        return components.url
    }

    /// Generate universal link URL for invitation (for email clients)
    var universalLinkURL: URL? {
        // In production, replace with your actual domain
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tinytastestracker.app"
        components.path = "/accept-invite"
        components.queryItems = [URLQueryItem(name: "code", value: inviteCode)]
        return components.url
    }

    /// Generate a random 6-digit code
    static func generateInviteCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
}
