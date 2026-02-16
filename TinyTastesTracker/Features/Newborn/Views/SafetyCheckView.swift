import SwiftUI

struct SafetyCheckView: View {
    @Bindable var appState: AppState
    
    @State private var isChecking = false
    @State private var safetyReport: NewbornSafetyReport?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(color: appState.themeColor)
                
                ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.pink.gradient)

                        Text("Is It Normal?")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Get personalized safety guidance based on your baby's daily logs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                    
                    // Daily Metrics Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(
                                title: "Wet Diapers",
                                value: "\(todayWetDiapers)",
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Dirty Diapers",
                                value: "\(todayDirtyDiapers)",
                                color: .brown
                            )
                            
                            MetricCard(
                                title: "Feedings",
                                value: "\(todayFeedings)",
                                color: .pink
                            )
                            
                            MetricCard(
                                title: "Sleep Hours",
                                value: String(format: "%.1f", todaySleepHours),
                                color: .indigo
                            )
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Check Button
                    Button {
                        performSafetyCheck()
                    } label: {
                        HStack {
                            if isChecking {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                SageIcon(size: .medium, style: .monochrome(.white))
                            }
                            Text(isChecking ? "Checking..." : "Run Safety Check")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isChecking)
                    
                    // Safety Report
                    if let report = safetyReport {
                        SafetyReportCard(report: report)
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            }
            .navigationTitle("Safety Check")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayWetDiapers: Int {
        appState.todayStats.wetDiapers
    }
    
    private var todayDirtyDiapers: Int {
        appState.todayStats.dirtyDiapers
    }
    
    private var todayFeedings: Int {
        appState.todayStats.feedingCount
    }
    
    private var todaySleepHours: Double {
        appState.todayStats.sleepHours
    }
    
    // MARK: - Actions
    
    private func performSafetyCheck() {
        isChecking = true
        errorMessage = nil
        
        Task {
            do {
                let babyAgeMonths = appState.userProfile?.ageInMonths ?? 0
                
                let report = try await appState.geminiService.checkNewbornSafety(
                    wetDiapers: todayWetDiapers,
                    dirtyDiapers: todayDirtyDiapers,
                    feedings: todayFeedings,
                    sleepHours: todaySleepHours,
                    ageInMonths: babyAgeMonths
                )
                
                await MainActor.run {
                    safetyReport = report
                    isChecking = false
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to perform safety check: \(error.localizedDescription)"
                    isChecking = false
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SafetyReportCard: View {
    let report: NewbornSafetyReport
    
    var statusColor: Color {
        switch report.overallStatus.lowercased() {
        case "normal": return .green
        case "monitor": return .orange
        case "concern": return .red
        default: return .gray
        }
    }
    
    var statusIcon: String {
        switch report.overallStatus.lowercased() {
        case "normal": return "checkmark.circle.fill"
        case "monitor": return "exclamationmark.triangle.fill"
        case "concern": return "exclamationmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Header
            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                
                VStack(alignment: .leading) {
                    Text("Status: \(report.overallStatus)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(report.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Concerns
            if !report.concerns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Areas to Monitor", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    
                    ForEach(report.concerns, id: \.self) { concern in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(concern)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Recommendations
            if !report.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recommendations", systemImage: "lightbulb.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(recommendation)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // When to Call Doctor
            if report.callDoctorIf {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "phone.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    
                    Text("Consider contacting your pediatrician if these patterns continue or worsen.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Data Model

struct NewbornSafetyReport: Codable {
    let overallStatus: String  // "Normal", "Monitor", "Concern"
    let summary: String
    let concerns: [String]
    let recommendations: [String]
    let callDoctorIf: Bool
}
