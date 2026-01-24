//
//  TinyTastesTrackerApp.swift
//  TinyTastesTracker
//

import SwiftUI
import SwiftData

@main
struct TinyTastesTrackerApp: App {
    var sharedModelContainer: ModelContainer = SharedModelContainer.shared
    
    init() {
        // Setup notification categories on app launch
        NotificationManager.shared.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
