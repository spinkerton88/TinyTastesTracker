//
//  DemoModeView.swift
//  TinyTastesTracker
//
//  Settings view for loading and managing sample data
//

import SwiftUI

struct DemoModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState // Kept for consistency, unused if disabled

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
                    
                    Text("Demo Mode is currently unavailable while we upgrade our database to the cloud. Please check back later!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("What's Included") {
                DemoFeatureRow(icon: "person.2.fill", title: "3 Child Profiles", description: "Emma (4mo), Liam (15mo), Olivia (8mo)")
                DemoFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Growth Data", description: "10-12 measurements per child")
                DemoFeatureRow(icon: "fork.knife.circle.fill", title: "Meal Logs", description: "50-100 meals across 30 days")
                DemoFeatureRow(icon: "moon.stars.fill", title: "Newborn Logs", description: "Sleep, nursing, diapers for Emma")
                DemoFeatureRow(icon: "book.fill", title: "Sample Recipes", description: "8 kid-friendly recipes with instructions")
            }
            
            Section("Benefits") {
                BenefitRow(icon: "eye.fill", text: "See how features look with real data")
                BenefitRow(icon: "chart.bar.fill", text: "Explore comparison and analytics views")
                BenefitRow(icon: "camera.fill", text: "Take screenshots for sharing")
                BenefitRow(icon: "testtube.2", text: "Test features risk-free")
            }
            
            Section {
                Button {
                    // Action disabled
                } label: {
                    HStack {
                        Spacer()
                        Text("Coming Soon")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(true)
                .listRowBackground(Color.gray.opacity(0.3))
                .foregroundStyle(.white)
            } footer: {
               Text("We are migrating to a more secure cloud database. Demo data will be restored in a future update.")
            }
        }
        .navigationTitle("Demo Mode")
        .navigationBarTitleDisplayMode(.inline)
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
