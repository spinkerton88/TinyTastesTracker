//
//  NotificationManager.swift
//  TinyTastesTracker
//
//  Centralized notification scheduling and management service
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
@Observable
class NotificationManager {
    // MARK: - Published Properties
    var permissionStatus: UNAuthorizationStatus = .notDetermined
    var feedNotificationsEnabled: Bool = false
    var allergenNotificationsEnabled: Bool = true

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifiers
    private let feedReminderIdentifier = "com.tinytastes.feed.reminder"
    private let allergenCheckInIdentifier = "com.tinytastes.allergen.checkin"

    // MARK: - Initialization
    init() {
        Task {
            await checkPermissionStatus()
            loadSettings()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    /// - Returns: True if permissions were granted, false otherwise
    func requestPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await checkPermissionStatus()
            return granted
        } catch {
            print("Error requesting notification permissions: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }
    
    // MARK: - Feed Reminder Notifications
    
    /// Schedule a feed reminder notification
    /// - Parameters:
    ///   - nextFeedTime: The expected time of the next feed
    ///   - leadTimeMinutes: How many minutes before the feed to send the notification
    ///   - childName: Name of the child for personalization
    func scheduleFeedReminder(
        nextFeedTime: Date,
        leadTimeMinutes: Int,
        childName: String
    ) async throws {
        // Cancel any existing feed reminders
        await cancelFeedReminders()
        
        // Calculate notification time
        let notificationTime = nextFeedTime.addingTimeInterval(-Double(leadTimeMinutes * 60))
        
        // Don't schedule if notification time is in the past
        guard notificationTime > Date() else {
            print("Notification time is in the past, skipping")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Feeding Time Soon"
        content.body = "\(childName) will be hungry in \(leadTimeMinutes) minutes"
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        
        // Add custom data
        content.userInfo = [
            "type": "feed_reminder",
            "childName": childName,
            "nextFeedTime": nextFeedTime.timeIntervalSince1970
        ]
        
        // Create trigger
        let timeInterval = notificationTime.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: feedReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        try await notificationCenter.add(request)
        
        print("Scheduled feed reminder for \(notificationTime)")
    }
    
    /// Cancel all feed reminder notifications
    func cancelFeedReminders() async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [feedReminderIdentifier]
        )
    }
    
    // MARK: - Allergen Monitoring Notifications
    
    /// Schedule an allergen check-in notification
    /// - Parameters:
    ///   - allergenName: Name of the allergen
    ///   - delayHours: Hours to wait before sending the check-in notification
    ///   - childName: Name of the child for personalization
    ///   - foodName: Optional name of the food containing the allergen
    func scheduleAllergenCheckIn(
        allergenName: String,
        delayHours: Int,
        childName: String,
        foodName: String? = nil
    ) async throws {
        // Create unique identifier for this allergen check-in
        let identifier = "\(allergenCheckInIdentifier).\(UUID().uuidString)"
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Allergen Check-In: \(allergenName)"
        
        if let foodName = foodName {
            content.body = "It's been \(delayHours) hours since \(childName) had \(foodName). How are they doing?"
        } else {
            content.body = "It's been \(delayHours) hours since \(childName) was exposed to \(allergenName). Check for any reactions."
        }
        
        content.sound = .default
        content.categoryIdentifier = "ALLERGEN_CHECKIN"
        
        // Add custom data
        content.userInfo = [
            "type": "allergen_checkin",
            "allergenName": allergenName,
            "childName": childName,
            "exposureTime": Date().timeIntervalSince1970
        ]
        
        // Create trigger
        let timeInterval = Double(delayHours * 3600)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        try await notificationCenter.add(request)
        
        let checkInTime = Date().addingTimeInterval(timeInterval)
        print("Scheduled allergen check-in for \(allergenName) at \(checkInTime)")
    }
    
    /// Cancel all allergen check-in notifications
    func cancelAllAllergenCheckIns() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let allergenIdentifiers = pending
            .filter { $0.identifier.hasPrefix(allergenCheckInIdentifier) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: allergenIdentifiers
        )
    }
    
    /// Cancel a specific allergen check-in notification
    /// - Parameter identifier: The notification identifier to cancel
    func cancelAllergenCheckIn(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }
    
    // MARK: - Notification Actions
    
    /// Setup notification categories and actions
    func setupNotificationCategories() {
        // Feed reminder actions
        let markAsFedAction = UNNotificationAction(
            identifier: "MARK_AS_FED",
            title: "Mark as Fed",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 15 min",
            options: []
        )
        
        let feedCategory = UNNotificationCategory(
            identifier: "FEED_REMINDER",
            actions: [markAsFedAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Allergen check-in actions
        let noReactionAction = UNNotificationAction(
            identifier: "NO_REACTION",
            title: "No Reaction",
            options: []
        )
        
        let reportReactionAction = UNNotificationAction(
            identifier: "REPORT_REACTION",
            title: "Report Reaction",
            options: [.foreground]
        )
        
        let allergenCategory = UNNotificationCategory(
            identifier: "ALLERGEN_CHECKIN",
            actions: [noReactionAction, reportReactionAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            feedCategory,
            allergenCategory
        ])
    }
    
    // MARK: - Settings Persistence
    
    /// Load notification settings from UserDefaults
    private func loadSettings() {
        feedNotificationsEnabled = UserDefaults.standard.bool(
            forKey: "feed_notifications_enabled"
        )
        allergenNotificationsEnabled = UserDefaults.standard.bool(
            forKey: "allergen_notifications_enabled"
        )
        
        // Default allergen notifications to true if not set
        if !UserDefaults.standard.bool(forKey: "allergen_notifications_initialized") {
            allergenNotificationsEnabled = true
            UserDefaults.standard.set(true, forKey: "allergen_notifications_initialized")
        }
    }
    
    /// Save notification settings to UserDefaults
    func saveSettings() {
        UserDefaults.standard.set(
            feedNotificationsEnabled,
            forKey: "feed_notifications_enabled"
        )
        UserDefaults.standard.set(
            allergenNotificationsEnabled,
            forKey: "allergen_notifications_enabled"
        )
    }
    
    // MARK: - Utility Methods
    
    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await getPendingNotifications()
        return requests.count
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

// MARK: - Supporting Types

extension NotificationManager {
    enum NotificationError: LocalizedError {
        case permissionDenied
        case invalidTime
        case schedulingFailed
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Notification permissions have been denied. Please enable them in Settings."
            case .invalidTime:
                return "The notification time is invalid or in the past."
            case .schedulingFailed:
                return "Failed to schedule notification. Please try again."
            }
        }
    }
}
