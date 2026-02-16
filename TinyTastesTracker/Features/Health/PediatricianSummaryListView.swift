//
//  PediatricianSummaryListView.swift
//  TinyTastesTracker
//
//  List view of all generated pediatrician summaries
//

import SwiftUI

struct PediatricianSummaryListView: View {
    @Bindable var appState: AppState

    @State private var showingCreateSheet = false
    @State private var selectedStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var selectedEndDate = Date()
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private var currentChildSummaries: [PediatricianSummary] {
        guard let currentChild = appState.userProfile else { return [] }
        return appState.pediatricianSummaries.filter { $0.childId == currentChild.id }
    }

    var body: some View {
        @Bindable var healthManager = appState.healthManager
        
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if appState.healthManager.pediatricianSummaries.isEmpty {
                    emptyState
                } else {
                    summaryList(healthManager: healthManager)
                }
                
                // Loading Overlay
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Generating summary...")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("This may take a moment")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .navigationTitle("Checkup Prep")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Create new summary")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                createSummarySheet
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundStyle(appState.themeColor)

            Text("No Summaries Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create your first Checkup Prep report to share health data with your pediatrician")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingCreateSheet = true
            } label: {
                Label("Create Summary", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(appState.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top)
        }
        .padding()
    }

    private func summaryList(healthManager: HealthManager) -> some View {
        List {
            ForEach(currentChildSummaries) { summary in
                if let index = healthManager.pediatricianSummaries.firstIndex(where: { $0.id == summary.id }) {
                    NavigationLink(destination: SummaryDetailView(
                        summary: Bindable(healthManager).pediatricianSummaries[index],
                        appState: appState
                    )) {
                        SummaryRow(summary: summary, themeColor: appState.themeColor)
                    }
                }
            }
            .onDelete(perform: deleteSummaries)
        }
    }

    private var createSummarySheet: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From", selection: $selectedStartDate, displayedComponents: .date)
                    DatePicker("To", selection: $selectedEndDate, displayedComponents: .date)
                }

                Section {
                    Text("This will analyze all tracking data between these dates and generate a professional summary for your pediatrician.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            await generateSummary()
                        }
                    }
                    .disabled(isGenerating || selectedStartDate > selectedEndDate)
                }
            }
        }
    }

    private func generateSummary() async {
        guard let currentChild = appState.userProfile else { return }

        isGenerating = true
        defer { isGenerating = false }

        do {
            guard let childId = currentChild.id else {
                print("❌ No child ID found")
                return
            }
            
            print("🏥 Starting summary generation for child: \(childId)")
            print("📅 Date range: \(selectedStartDate) to \(selectedEndDate)")

            let summary = try await DataAggregationService.shared.generateSummary(
                for: childId,
                from: selectedStartDate,
                to: selectedEndDate,
                appState: appState
            )

            print("✅ Summary generated successfully")
            print("📊 Highlights: \(summary.highlights.count)")
            print("⚠️ Concerns: \(summary.concerns.count)")
            print("❓ Questions: \(summary.suggestedQuestions.count)")

            // Save via HealthManager linked in AppState
            appState.healthManager.saveSummary(summary)

            print("💾 Summary saved to database via HealthManager")

            await MainActor.run {
                showingCreateSheet = false
                HapticManager.success()
            }
        } catch {
            print("❌ Error generating summary: \(error)")
            print("❌ Error details: \(error.localizedDescription)")

            await MainActor.run {
                errorMessage = "Failed to generate summary: \(error.localizedDescription)"
                showErrorAlert = true
                HapticManager.error()
            }
        }
    }

    private func deleteSummaries(at offsets: IndexSet) {
        for index in offsets {
            let summary = currentChildSummaries[index]
            appState.healthManager.deleteSummary(summary)
        }
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let summary: PediatricianSummary
    let themeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateRangeText)
                    .font(.headline)

                Spacer()

                Text(summary.generatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !summary.highlights.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(themeColor)
                    Text("\(summary.highlights.count) highlights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !summary.concerns.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                    Text("\(summary.concerns.count) concerns noted")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checkup summary from \(dateRangeText). \(summary.highlights.count) highlights, \(summary.concerns.count) concerns.")
        .accessibilityHint("Double tap to view full report")
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let start = formatter.string(from: summary.startDate)
        let end = formatter.string(from: summary.endDate)

        return "\(start) - \(end)"
    }
}
