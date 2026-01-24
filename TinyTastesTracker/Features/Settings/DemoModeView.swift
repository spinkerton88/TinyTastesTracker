//
//  DemoModeView.swift
//  TinyTastesTracker
//
//  Settings view for loading and managing sample data
//

import SwiftUI
import SwiftData

struct DemoModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState

    @State private var showingConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingNoDataAlert = false

    private var isUsingSampleData: Bool {
        UserDefaults.standard.bool(forKey: "isUsingSampleData")
    }

    private var hasBackup: Bool {
        UserDataBackupService.hasBackup()
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        SageIcon(size: .large, style: .gradient)
                        
                        Spacer()
                    }
                    
                    Text("Demo Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Load realistic sample data to explore all features of Tiny Tastes Tracker.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            if isUsingSampleData {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sample Data Active")
                                .fontWeight(.medium)
                            Text("You're currently using demo data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    if hasBackup {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Data is Safe")
                                    .fontWeight(.medium)
                                Text("Your original data is backed up")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Section("What's Included") {
                FeatureRow(icon: "person.2.fill", title: "3 Child Profiles", description: "Emma (4mo), Liam (15mo), Olivia (8mo)")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Growth Data", description: "10-12 measurements per child")
                FeatureRow(icon: "fork.knife.circle.fill", title: "Meal Logs", description: "50-100 meals across 30 days")
                FeatureRow(icon: "moon.stars.fill", title: "Newborn Logs", description: "Sleep, nursing, diapers for Emma")
                FeatureRow(icon: "book.fill", title: "Sample Recipes", description: "8 kid-friendly recipes with instructions")
            }
            
            Section("Benefits") {
                BenefitRow(icon: "eye.fill", text: "See how features look with real data")
                BenefitRow(icon: "chart.bar.fill", text: "Explore comparison and analytics views")
                BenefitRow(icon: "camera.fill", text: "Take screenshots for sharing")
                BenefitRow(icon: "testtube.2", text: "Test features risk-free")
            }
            
            Section {
                Button {
                    showingConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isUsingSampleData ? "Reload Sample Data" : "Load Sample Data")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading)
                .listRowBackground(Color.purple)
                .foregroundStyle(.white)
            }
            
            if isUsingSampleData {
                Section {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.uturn.backward")
                            Text(hasBackup ? "Restore My Data" : "Exit Demo Mode")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.blue)
                    .foregroundStyle(.white)
                } footer: {
                    if hasBackup {
                        Text("This will remove sample data and restore your original data.")
                            .font(.caption)
                    } else {
                        Text("This will remove sample data. You'll need to set up your profile again.")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Demo Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Load Sample Data?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Load", role: .destructive) {
                loadSampleData()
            }
        } message: {
            if UserDataBackupService.hasUserData(context: modelContext) {
                Text("Your current data will be backed up and can be restored later.")
            } else {
                Text("This will load sample data so you can explore all features.")
            }
        }
        .alert(hasBackup ? "Restore Your Data?" : "Exit Demo Mode?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(hasBackup ? "Restore" : "Exit") {
                clearSampleData()
            }
        } message: {
            if hasBackup {
                Text("This will remove sample data and restore your original data.")
            } else {
                Text("This will remove sample data. You'll be taken to the setup screen.")
            }
        }
        .alert("Sample Data Loaded!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Explore the app with realistic demo data. You can restore your data anytime from this screen.")
        }
        .alert("Demo Mode Ended", isPresented: $showingNoDataAlert) {
            Button("OK") {
                // Navigate to setup - handled in clearSampleData
            }
        } message: {
            Text("Sample data has been removed. Let's set up your profile.")
        }
    }
    
    // MARK: - Actions

    private func loadSampleData() {
        isLoading = true

        // Track analytics
        AnalyticsService.shared.trackSampleDataLoaded(source: "settings")

        Task {
            await Task.detached {
                // The backup is handled inside generateSampleData
                SampleDataGenerator.generateSampleData(context: modelContext, backupUserData: true)
            }.value

            // Wait for visual feedback
            try? await Task.sleep(for: .seconds(1))

            await MainActor.run {
                // Reload app state
                appState.loadData(context: modelContext)

                // Mark as using sample data
                UserDefaults.standard.set(true, forKey: "isUsingSampleData")

                isLoading = false
                showingSuccess = true
            }
        }
    }

    private func clearSampleData() {
        // Track analytics
        AnalyticsService.shared.trackSampleDataCleared()

        Task {
            let hasBackupData = UserDataBackupService.hasBackup()

            await Task.detached {
                if hasBackupData {
                    // Restore user data from backup
                    let success = UserDataBackupService.restoreUserData(context: modelContext)
                    if !success {
                        print("⚠️ Failed to restore user data")
                    }
                } else {
                    // Just clear sample data
                    SampleDataGenerator.clearAllData(context: modelContext)
                }
            }.value

            await MainActor.run {
                // Mark as not using sample data
                UserDefaults.standard.set(false, forKey: "isUsingSampleData")

                // Reload app state
                appState.loadData(context: modelContext)

                // Check if user has any data
                let hasData = UserDataBackupService.hasUserData(context: modelContext)

                if !hasData {
                    // No data - need to show onboarding
                    // Set the flag so app will show welcome screen
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    showingNoDataAlert = true
                } else {
                    // Has data - just dismiss
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        DemoModeView(appState: AppState())
    }
}
