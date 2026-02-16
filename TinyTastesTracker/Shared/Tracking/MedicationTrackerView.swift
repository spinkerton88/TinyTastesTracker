//
//  MedicationTrackerView.swift
//  TinyTastesTracker
//
//  Shared component for medication logging across all modes
//

import SwiftUI

struct MedicationTrackerView: View {
    let mode: AppMode
    @Bindable var appState: AppState
    @State private var showingMedicationSheet = false
    
    var medicationLogs: [MedicationLog] {
        appState.medicationLogs
    }
    
    var lastMedication: String {
        guard let lastMed = medicationLogs.last else {
            return "No medications logged yet"
        }
        return lastMed.medicineName
    }
    
    var lastMedicationTime: String {
        guard let lastMed = medicationLogs.last else {
            return ""
        }
        return formatRelativeTime(from: lastMed.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Medications")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !lastMedicationTime.isEmpty {
                    Text(lastMedicationTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Last medication summary
            if !medicationLogs.isEmpty {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(appState.themeColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Medication")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastMedication)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last medication: \(lastMedication), \(lastMedicationTime)")
            }
            
            // Log medication button
            Button(action: { showingMedicationSheet = true }) {
                HStack {
                    Image(systemName: "pills.fill")
                    Text("Log Medication")
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Recent medication list
            if !medicationLogs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text ("Recent Medications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(Array(medicationLogs.suffix(3).reversed()), id: \.id) { log in
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(appState.themeColor.opacity(0.7))
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.medicineName)
                                    .font(.caption)
                                Text(log.dosage)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingMedicationSheet) {
            MedicationSheet(appState: appState)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatRelativeTime(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}
