//
//  DemoModeView.swift
//  TinyTastesTracker
//
//  Settings view for loading and managing sample data
//

import SwiftUI

struct DemoModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    
    @State private var isLoading = false
    @State private var showSuccess = false

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
                    
                    Text("Load sample data to explore all features with realistic content. Perfect for taking App Store screenshots!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("What's Included") {
                DemoFeatureRow(icon: "person.2.fill", title: "Sample Child Profile", description: "Sage (8mo) - Explorer mode")
                DemoFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Growth Measurements", description: "3 measurements tracking weight, height, head circumference")
                DemoFeatureRow(icon: "fork.knife.circle.fill", title: "Food Logs", description: "8 tried foods with reactions")
                DemoFeatureRow(icon: "calendar", title: "Meal Logs", description: "6 meals over 3 days (breakfast & lunch)")
                DemoFeatureRow(icon: "moon.stars.fill", title: "Sleep Logs", description: "3 sleep sessions with quality ratings")
                DemoFeatureRow(icon: "heart.circle.fill", title: "Nursing Logs", description: "2 nursing sessions")
                DemoFeatureRow(icon: "rectangle.3.group.fill", title: "Diaper Logs", description: "3 diaper changes")
                DemoFeatureRow(icon: "book.fill", title: "Sample Recipe", description: "Sweet Potato & Banana Mash")
                DemoFeatureRow(icon: "stethoscope", title: "Pediatrician Summary", description: "30-day health report with AI insights")
            }
            
            Section("Benefits") {
                BenefitRow(icon: "eye.fill", text: "See how features look with real data")
                BenefitRow(icon: "chart.bar.fill", text: "Explore comparison and analytics views")
                BenefitRow(icon: "camera.fill", text: "Take screenshots for sharing")
                BenefitRow(icon: "testtube.2", text: "Test features risk-free")
            }
            
            Section {
                Button {
                    Task {
                        await loadDemoData()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Load Demo Data")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading)
                .listRowBackground(appState.themeColor)
                .foregroundStyle(.white)
            } footer: {
               Text("This will create a sample child profile with demo data. You can delete it later from Settings.")
            }
        }
        .navigationTitle("Demo Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Demo Data Loaded!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Sample data has been created. The app will now show the demo profile.")
        }
    }
    
    @MainActor
    private func loadDemoData() async {
        guard let ownerId = appState.currentOwnerId else {
            print("No owner ID available")
            return
        }
        
        isLoading = true
        
        // Generate the demo data
        await SampleDataGenerator.generateSampleData(ownerId: ownerId, appState: appState)
        
        // Wait a moment for Firestore to propagate the data
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Reload profile manager to pick up the new profile
        appState.profileManager.loadProfiles(userId: ownerId)
        
        // Wait for profile to be set
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get the demo child ID and load its data
        if let demoChildId = UserDefaults.standard.string(forKey: "ProfileManager.activeProfileId") {
            appState.updateActiveChildData(childId: demoChildId)
        }
        
        isLoading = false
        showSuccess = true
    }
}

// MARK: - Supporting Views

private struct DemoFeatureRow: View {
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
