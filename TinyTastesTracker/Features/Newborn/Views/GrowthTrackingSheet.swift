//
//  GrowthTrackingSheet.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct GrowthTrackingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState

    @State private var weightStr: String = ""
    @State private var heightStr: String = ""
    @State private var headCircStr: String = ""
    @State private var notes: String = ""
    @State private var measurementDate = Date()
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Measurement Date") {
                    DatePicker("Date", selection: $measurementDate, displayedComponents: .date)
                }
                
                Section(header: Text("Measurements"), footer: Text("Enter at least one measurement")) {
                    HStack {
                        Text("Weight")
                            .frame(width: 100, alignment: .leading)
                        TextField("0.0", text: $weightStr)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Height")
                            .frame(width: 100, alignment: .leading)
                        TextField("0.0", text: $heightStr)
                            .keyboardType(.decimalPad)
                        Text("inches")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Head Circ.")
                            .frame(width: 100, alignment: .leading)
                        TextField("0.0", text: $headCircStr)
                            .keyboardType(.decimalPad)
                        Text("inches")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Pediatrician visit, growth spurt, etc...", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                
                if !appState.growthMeasurements.isEmpty {
                    Section("Recent Measurements") {
                        ForEach(appState.growthMeasurements.prefix(5), id: \.id) { measurement in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 12) {
                                    if let weight = measurement.weight {
                                        Text("\(String(format: "%.1f", weight)) lbs")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let height = measurement.height {
                                        Text("\(String(format: "%.1f", height))\"")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let head = measurement.headCircumference {
                                        Text("HC: \(String(format: "%.1f", head))\"")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Growth Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeasurement()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasAnyMeasurement || isSaving)
                }
            }
        }
    }
    
    private var hasAnyMeasurement: Bool {
        !weightStr.isEmpty || !heightStr.isEmpty || !headCircStr.isEmpty
    }
    
    private func saveMeasurement() {
        Task {
            isSaving = true
            defer { isSaving = false }
            
            do {
                let weight = Double(weightStr)
                let height = Double(heightStr)
                let headCirc = Double(headCircStr)
                
                try await appState.saveGrowthMeasurement(
                    weight: weight,
                    height: height,
                    headCircumference: headCirc,
                    notes: notes.isEmpty ? nil : notes
                )
                
                errorPresenter.showSuccess("Growth measurement saved")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }
}
