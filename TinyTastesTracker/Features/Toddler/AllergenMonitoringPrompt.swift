//
//  AllergenMonitoringPrompt.swift
//  TinyTastesTracker
//
//  Modal prompt after logging high-risk allergen food
//

import SwiftUI

struct AllergenMonitoringPrompt: View {
    let foodName: String
    let allergenName: String
    let allergyRisk: AllergyRisk
    let childName: String
    let forceTimer: Bool
    let notificationManager: NotificationManager

    @Environment(\.dismiss) private var dismiss
    @AppStorage("allergen_checkin_duration") private var checkInDuration: Int = 2

    @State private var isSchedulingNotification = false
    @State private var showingSuccess = false
    @State private var enableTimer: Bool

    init(
        foodName: String,
        allergenName: String,
        allergyRisk: AllergyRisk,
        childName: String,
        forceTimer: Bool = false,
        notificationManager: NotificationManager
    ) {
        self.foodName = foodName
        self.allergenName = allergenName
        self.allergyRisk = allergyRisk
        self.childName = childName
        self.forceTimer = forceTimer
        self.notificationManager = notificationManager

        // Default timer to ON for high/medium risk OR if forced, OFF for low risk
        _enableTimer = State(initialValue: forceTimer || allergyRisk != .low)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Risk level indicator
                    riskLevelBadge

                    // Allergen info
                    allergenInfoCard

                    // Timer settings
                    timerSettingsCard

                    // Symptoms to watch
                    symptomsCard

                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Allergen Exposure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Reminder Set", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You'll receive a check-in reminder in \(checkInDuration) \(checkInDuration == 1 ? "hour" : "hours").")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Allergen Logged")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("You just logged **\(foodName)** which contains **\(allergenName)**")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Risk Level Badge

    private var riskLevelBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(allergyRisk.color)
                .frame(width: 10, height: 10)

            Text(allergyRisk.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(allergyRisk.color.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Allergen Info Card
    
    private var allergenInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("About \(allergenName)", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            
            Text(allergenDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timer Settings Card

    private var timerSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Check-In Reminder", systemImage: "bell.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            if forceTimer {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Timer Required")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("This food contains a known allergy. A check-in reminder is required for safety.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } else {
                Toggle(isOn: $enableTimer) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set check-in timer")
                            .font(.subheadline)
                        Text("Get notified to check on your child after exposure")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)
            }

            if enableTimer {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reminder in:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Duration", selection: $checkInDuration) {
                        Text("1 hour").tag(1)
                        Text("2 hours").tag(2)
                        Text("3 hours").tag(3)
                        Text("4 hours").tag(4)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Symptoms Card
    
    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Symptoms to Watch For", systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 12) {
                SymptomRow(icon: "face.smiling", text: "Hives or skin rash", severity: .mild)
                SymptomRow(icon: "wind", text: "Difficulty breathing or wheezing", severity: .severe)
                SymptomRow(icon: "drop.fill", text: "Swelling of lips, face, or tongue", severity: .severe)
                SymptomRow(icon: "stomach", text: "Vomiting or diarrhea", severity: .moderate)
                SymptomRow(icon: "heart.fill", text: "Rapid heartbeat", severity: .severe)
            }
            
            Divider()
            
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.red)
                
                Text("Call emergency services immediately if you notice severe symptoms")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if enableTimer {
                Button {
                    Task {
                        await scheduleCheckInReminder()
                    }
                } label: {
                    HStack {
                        if isSchedulingNotification {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bell.badge.fill")
                            Text("Set \(checkInDuration)-Hour Check-In Reminder")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSchedulingNotification)
            }

            // Only show cancel/done button if timer is not forced
            if !forceTimer {
                Button {
                    dismiss()
                } label: {
                    Text(enableTimer ? "Cancel" : "Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func scheduleCheckInReminder() async {
        isSchedulingNotification = true
        
        // Check if notifications are enabled
        if notificationManager.permissionStatus != .authorized {
            let granted = await notificationManager.requestPermissions()
            if !granted {
                isSchedulingNotification = false
                return
            }
        }
        
        // Schedule the notification
        do {
            try await notificationManager.scheduleAllergenCheckIn(
                allergenName: allergenName,
                delayHours: checkInDuration,
                childName: childName,
                foodName: foodName
            )
            
            showingSuccess = true
        } catch {
            print("Error scheduling allergen check-in: \(error.localizedDescription)")
        }
        
        isSchedulingNotification = false
    }
    
    // MARK: - Computed Properties
    
    private var allergenDescription: String {
        switch allergenName.lowercased() {
        case "peanuts", "peanut":
            return "Peanut allergies are one of the most common food allergies in children. Reactions can range from mild to severe. Most reactions occur within 2 hours of exposure."
        case "tree nuts", "tree nut":
            return "Tree nut allergies include almonds, walnuts, cashews, and more. They can cause severe reactions and often persist throughout life."
        case "milk", "dairy":
            return "Milk allergy is common in infants and young children. Symptoms typically appear within minutes to hours after consuming dairy products."
        case "eggs", "egg":
            return "Egg allergies are common in children and often outgrown by school age. Reactions usually occur within minutes to hours."
        case "soy":
            return "Soy allergies are common in infants and young children. Most children outgrow soy allergies by age 10."
        case "wheat":
            return "Wheat allergy can cause digestive issues, hives, or respiratory problems. It's different from celiac disease."
        case "fish":
            return "Fish allergies can cause severe reactions and typically persist throughout life. Reactions usually occur within minutes to hours."
        case "shellfish":
            return "Shellfish allergies can be severe and life-threatening. They often develop later in childhood and persist into adulthood."
        default:
            return "This is a high-risk allergen that can cause allergic reactions. Monitor your child closely for the next few hours."
        }
    }
}

// MARK: - Supporting Views

struct SymptomRow: View {
    let icon: String
    let text: String
    let severity: Severity
    
    enum Severity {
        case mild, moderate, severe
        
        var color: Color {
            switch self {
            case .mild: return .yellow
            case .moderate: return .orange
            case .severe: return .red
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(severity.color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
            
            Circle()
                .fill(severity.color)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    AllergenMonitoringPrompt(
        foodName: "Peanut Butter",
        allergenName: "Peanuts",
        allergyRisk: .high,
        childName: "Emma",
        notificationManager: NotificationManager()
    )
}

#Preview("Shellfish") {
    AllergenMonitoringPrompt(
        foodName: "Shrimp",
        allergenName: "Shellfish",
        allergyRisk: .high,
        childName: "Oliver",
        notificationManager: NotificationManager()
    )
}

#Preview("Eggs") {
    AllergenMonitoringPrompt(
        foodName: "Scrambled Eggs",
        allergenName: "Eggs",
        allergyRisk: .medium,
        childName: "Sophia",
        notificationManager: NotificationManager()
    )
}
