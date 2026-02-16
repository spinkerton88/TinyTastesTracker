//
//  PrivacySettingsView.swift
//  TinyTastesTracker
//
//  Created by Antigravity on 1/12/26.
//

import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var appState: AppState
    @State private var showingPrivacyPolicy = false
    @State private var showingDataDeletion = false
    @State private var showingExportOptions = false
    @State private var exportFormat: DataExportService.ExportFormat = .json
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportedFileURL: URL?
    
    var body: some View {
        List {
            // Privacy Policy Section
            Section {
                Button {
                    showingPrivacyPolicy = true
                } label: {
                    Label("View Privacy Policy", systemImage: "doc.text.fill")
                }
            } header: {
                Text("Privacy Information")
            } footer: {
                Text("Learn how we collect, use, and protect your data.")
            }
            
            // Data Export Section
            Section {
                Button {
                    showingExportOptions = true
                } label: {
                    Label("Export All Data", systemImage: "arrow.down.doc.fill")
                }
            } header: {
                Text("Data Portability")
            } footer: {
                Text("Export all your data in JSON or CSV format. This includes meal logs, sleep logs, growth data, recipes, and more.")
            }
            
            // Data Deletion Section
            Section {
                Button(role: .destructive) {
                    showingDataDeletion = true
                } label: {
                    Label("Delete Data", systemImage: "trash.fill")
                }
            } header: {
                Text("Data Management")
            } footer: {
                Text("Delete specific data types or all data. This action cannot be undone.")
            }
            
            // Third-Party Services Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ServiceRow(
                        name: "Google Gemini AI",
                        purpose: "AI recommendations and food analysis",
                        dataShared: "Questions, child's age/allergens, photos (when you use AI features)"
                    )
                    
                    Divider()
                    
                    ServiceRow(
                        name: "Open Food Facts",
                        purpose: "Nutrition data for packaged foods",
                        dataShared: "Barcode numbers only"
                    )
                    
                    Divider()
                    
                    ServiceRow(
                        name: "Apple Reminders",
                        purpose: "Shopping list sync (optional)",
                        dataShared: "Shopping list items (if you export)"
                    )
                }
            } header: {
                Text("Third-Party Services")
            } footer: {
                Text("These services process data when you use specific features. Most data stays on your device.")
            }
            
            // Data Storage Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "iphone", title: "Local Storage", value: "All data stored on your device")
                    InfoRow(icon: "lock.fill", title: "Encryption", value: "Protected by iOS encryption")
                    InfoRow(icon: "icloud.fill", title: "Backups", value: "Included in iCloud/iTunes backups")
                    InfoRow(icon: "person.slash.fill", title: "Tracking", value: "No tracking or advertising")
                }
            } header: {
                Text("How We Store Your Data")
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDataDeletion) {
            DataDeletionView(appState: appState)
        }
        .confirmationDialog("Export Data", isPresented: $showingExportOptions) {
            Button("Export Backup (JSON)") {
                exportFormat = .json
                Task {
                    await exportData()
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Export a complete backup of your data in JSON format.")
        }
        .alert("Export Complete", isPresented: .constant(exportedFileURL != nil)) {
            Button("Share") {
                if let url = exportedFileURL {
                    shareFile(url: url)
                }
            }
            Button("OK") {
                exportedFileURL = nil
            }
        } message: {
            Text("Your data has been exported successfully. You can share or save the file.")
        }
        .alert("Export Error", isPresented: .constant(exportError != nil)) {
            Button("OK") {
                exportError = nil
            }
        } message: {
            if let error = exportError {
                Text(error)
            }
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Exporting data...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Export Data
    
    private func exportData() async {
        guard let profile = appState.userProfile else {
            exportError = "No user profile found."
            return
        }
        
        isExporting = true
        exportError = nil
        exportedFileURL = nil
        
        do {
            let url = try DataExportService.exportAllDataAsJSON(
                profile: profile,
                mealLogs: appState.mealLogs,
                triedFoods: appState.foodLogs,
                recipes: appState.recipes,
                customFoods: appState.customFoods,
                nursingLogs: appState.nursingLogs,
                sleepLogs: appState.sleepLogs,
                diaperLogs: appState.diaperLogs,
                bottleLogs: appState.bottleLogs,
                growthMeasurements: appState.growthMeasurements,
                pumpingLogs: appState.pumpingLogs,
                medicationLogs: appState.medicationLogs
            )
            exportedFileURL = url
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
        
        isExporting = false
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct ServiceRow: View {
    let name: String
    let purpose: String
    let dataShared: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
            
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Purpose:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Data shared:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dataShared)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView(appState: AppState())
    }
}
