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
    let childName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var notificationManager = NotificationManager.shared
    @AppStorage("allergen_checkin_duration") private var checkInDuration: Int = 2
    
    @State private var isSchedulingNotification = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Allergen info
                    allergenInfoCard
                    
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
            
            Text("High-Risk Allergen Logged")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("You just logged **\(foodName)** which contains **\(allergenName)**")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
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
            
            Button {
                dismiss()
            } label: {
                Text("No Thanks, I'll Monitor Manually")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        childName: "Emma"
    )
}

#Preview("Shellfish") {
    AllergenMonitoringPrompt(
        foodName: "Shrimp",
        allergenName: "Shellfish",
        childName: "Oliver"
    )
}

#Preview("Eggs") {
    AllergenMonitoringPrompt(
        foodName: "Scrambled Eggs",
        allergenName: "Eggs",
        childName: "Sophia"
    )
}
