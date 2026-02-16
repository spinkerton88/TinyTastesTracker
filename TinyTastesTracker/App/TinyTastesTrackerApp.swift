//
//  TinyTastesTrackerApp.swift
//  TinyTastesTracker
//

import SwiftUI

import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics

@main
struct TinyTastesTrackerApp: App {

    init() {
        FirebaseApp.configure()

        // Enable Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // Enable offline persistence for Firestore
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings

        // Setup notification categories on app launch
        // Create temporary instance for one-time setup
        let notificationManager = NotificationManager()
        notificationManager.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle invitation deep links
        // Format: tinytastes://accept-invite?code=123456
        guard url.scheme == "tinytastes" || url.scheme == "https",
              url.host == "accept-invite" || url.path.contains("accept-invite") else {
            return
        }

        // Extract invite code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }

        // Store the invite code for the app to handle
        UserDefaults.standard.set(code, forKey: "pendingInviteCode")
        NotificationCenter.default.post(name: .handleInviteDeepLink, object: code)
    }
}

extension Notification.Name {
    static let handleInviteDeepLink = Notification.Name("handleInviteDeepLink")
}
