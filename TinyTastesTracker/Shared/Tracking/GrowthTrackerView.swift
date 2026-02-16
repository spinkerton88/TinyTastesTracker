//
//  GrowthTrackerView.swift
//  TinyTastesTracker
//
//  Shared component for growth tracking across all modes
//

import SwiftUI

struct GrowthTrackerView: View {
    let mode: AppMode
    @Bindable var appState: AppState
    @State private var showingGrowthSheet = false
    
    var lastMeasurement: GrowthMeasurement? {
        appState.growthMeasurements.last
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Growth")
                .font(.title2)
                .fontWeight(.bold)
            
            // Last measurement summary
            if let measurement = lastMeasurement {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "figure.child")
                            .foregroundStyle(appState.themeColor.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 2) {
                           Text("Latest Measurement")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                if let weight = measurement.weight {
                                    let formatted = String(format: "%.1f", weight)
                                    Text("\(formatted) lbs")
                                }
                                if let height = measurement.height {
                                    let formatted = String(format: "%.1f", height)
                                    Text("\(formatted) in")
                                }
                            }
                            .font(.body)
                        }
                        
                        Spacer()
                        
                        Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Latest measurement: \(measurement.weight != nil ? String(format: "%.1f lbs", measurement.weight!) : "") \(measurement.height != nil ? String(format: "%.1f in", measurement.height!) : ""), on \(measurement.date.formatted(date: .abbreviated, time: .omitted))")
            }
            
            // Add measurement button
            Button(action: { showingGrowthSheet = true }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Log Measurement")
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingGrowthSheet) {
            GrowthTrackingSheet(appState: appState)
        }
    }
}
