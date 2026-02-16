//
//  NotificationSettingsView.swift
//  TinyTastesTracker
//
//  User interface for notification preferences
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var notificationManager: NotificationManager

    // Settings
    @AppStorage("feed_notification_lead_time") private var feedLeadTime: Int = 30
    @AppStorage("allergen_checkin_duration") private var allergenCheckInDuration: Int = 2

    // UI State
    @State private var showingPermissionAlert = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        NavigationStack {
            Form {
                permissionSection
                
                if notificationManager.permissionStatus == .authorized {
                    feedNotificationsSection
                    allergenNotificationsSection
                }
                
                aboutSection
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings", role: .none) {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive feed reminders and allergen check-ins.")
            }
        }
    }
    
    // MARK: - Permission Section
    
    private var permissionSection: some View {
        Section {
            HStack {
                Label("Permission Status", systemImage: permissionStatusIcon)
                    .foregroundStyle(permissionStatusColor)
                
                Spacer()
                
                Text(permissionStatusText)
                    .foregroundStyle(.secondary)
            }
            
            if notificationManager.permissionStatus != .authorized {
                Button {
                    Task {
                        await requestPermissions()
                    }
                } label: {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Enable Notifications")
                        }
                    }
                }
                .disabled(isRequestingPermission)
                .accessibilityHint("Double tap to prompt for system notification permissions")
            }
        } header: {
            Text("Permissions")
        } footer: {
            Text("Notifications help you stay on top of feeding schedules and monitor allergen exposure.")
        }
    }
    
    // MARK: - Feed Notifications Section
    
    private var feedNotificationsSection: some View {
        Section {
            Toggle("Feed Reminders", isOn: $notificationManager.feedNotificationsEnabled)
                .accessibilityLabel("Feed Reminders Switch")
                .onChange(of: notificationManager.feedNotificationsEnabled) { _, _ in
                    notificationManager.saveSettings()
                }
            
            if notificationManager.feedNotificationsEnabled {
                Picker("Lead Time", selection: $feedLeadTime) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("45 minutes").tag(45)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Feed Reminder Lead Time")
            }
        } header: {
            Text("Feed Notifications")
        } footer: {
            if notificationManager.feedNotificationsEnabled {
                Text("You'll receive a reminder \(feedLeadTimeText) before the next expected feeding time.")
            } else {
                Text("Get notified before your baby's next feeding time.")
            }
        }
    }
    
    // MARK: - Allergen Notifications Section
    
    private var allergenNotificationsSection: some View {
        Section {
            Toggle("Allergen Monitoring", isOn: $notificationManager.allergenNotificationsEnabled)
                .accessibilityLabel("Allergen Monitoring Switch")
                .onChange(of: notificationManager.allergenNotificationsEnabled) { _, _ in
                    notificationManager.saveSettings()
                }
            
            if notificationManager.allergenNotificationsEnabled {
                Picker("Check-In Duration", selection: $allergenCheckInDuration) {
                    Text("1 hour").tag(1)
                    Text("2 hours").tag(2)
                    Text("3 hours").tag(3)
                    Text("4 hours").tag(4)
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Allergen Monitoring")
        } footer: {
            if notificationManager.allergenNotificationsEnabled {
                Text("You'll receive a check-in reminder \(allergenCheckInDurationText) after logging high-risk allergen foods.")
            } else {
                Text("Get reminded to check for allergic reactions after introducing high-risk foods.")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feed Reminders")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Receive timely notifications before your baby's next feeding based on their feeding pattern.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allergen Check-Ins")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Get prompted to monitor for allergic reactions after introducing high-risk foods like peanuts, eggs, or shellfish.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("About Notifications")
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestPermissions() async {
        isRequestingPermission = true
        
        let granted = await notificationManager.requestPermissions()
        
        if granted {
            // Setup notification categories
            notificationManager.setupNotificationCategories()
        } else if notificationManager.permissionStatus == .denied {
            showingPermissionAlert = true
        }
        
        isRequestingPermission = false
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Computed Properties
    
    private var permissionStatusIcon: String {
        switch notificationManager.permissionStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined, .provisional, .ephemeral:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var permissionStatusColor: Color {
        switch notificationManager.permissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined, .provisional, .ephemeral:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var permissionStatusText: String {
        switch notificationManager.permissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var feedLeadTimeText: String {
        if feedLeadTime < 60 {
            return "\(feedLeadTime) minutes"
        } else {
            let hours = feedLeadTime / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
    
    private var allergenCheckInDurationText: String {
        return allergenCheckInDuration == 1 ? "1 hour" : "\(allergenCheckInDuration) hours"
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView(notificationManager: NotificationManager())
}

#Preview("Authorized") {
    let manager = NotificationManager()
    return NotificationSettingsView(notificationManager: manager)
        .onAppear {
            // Simulate authorized state for preview
            Task {
                await manager.checkPermissionStatus()
            }
        }
}
