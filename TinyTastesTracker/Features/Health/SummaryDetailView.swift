//
//  SummaryDetailView.swift
//  TinyTastesTracker
//
//  Detailed view of a single pediatrician summary
//

import SwiftUI

struct SummaryDetailView: View {
    @Binding var summary: PediatricianSummary
    @Bindable var appState: AppState
    @State private var isEditingNotes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // AI Summary Section
                summarySection

                // Highlights Section
                if !summary.highlights.isEmpty {
                    highlightsSection
                }

                // Concerns Section
                if !summary.concerns.isEmpty {
                    concernsSection
                }

                // Suggested Questions Section
                if !summary.suggestedQuestions.isEmpty {
                    suggestedQuestionsSection
                }

                // Metrics Sections
                sleepMetricsSection
                feedingMetricsSection

                if summary.explorerMetrics != nil {
                    explorerMetricsSection
                }

                diaperMetricsSection
                growthMetricsSection

                // Parent Notes Section
                parentNotesSection
            }
            .padding()
        }
        .navigationTitle("Doctor Visit Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: generateShareText()) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(appState.themeColor)
                Text("Summary")
                    .font(.headline)
            }

            Text(summary.aiSummary)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Key Highlights")
                    .font(.headline)
            }

            ForEach(Array(summary.highlights.enumerated()), id: \.offset) { index, highlight in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(highlight)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var concernsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Concerns")
                    .font(.headline)
            }

            ForEach(Array(summary.concerns.enumerated()), id: \.offset) { index, concern in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(concern)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.bubble.fill")
                    .foregroundStyle(appState.themeColor)
                Text("Questions for Your Pediatrician")
                    .font(.headline)
            }

            Text("Based on the data, here are some questions you might want to ask:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(summary.suggestedQuestions.enumerated()), id: \.offset) { index, question in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(appState.themeColor)
                    Text(question)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(appState.themeColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sleepMetricsSection: some View {
        MetricsCard(
            title: "Sleep Patterns",
            icon: "bed.double.fill",
            color: .indigo,
            metrics: [
                ("Avg Naps/Day", String(format: "%.1f", summary.sleepMetrics.avgNapsPerDay)),
                ("Avg Nap Duration", formatDuration(summary.sleepMetrics.avgNapDuration)),
                ("Total Sleep/Day", formatDuration(summary.sleepMetrics.avgTotalSleepTime)),
                ("Longest Stretch", formatDuration(summary.sleepMetrics.longestSleepStretch))
            ]
        )
    }

    private var feedingMetricsSection: some View {
        MetricsCard(
            title: "Feeding",
            icon: "fork.knife",
            color: .orange,
            metrics: [
                ("Avg Feeds/Day", String(format: "%.1f", summary.feedingMetrics.avgFeedsPerDay)),
                ("Avg Interval", formatDuration(summary.feedingMetrics.avgFeedingInterval)),
                summary.feedingMetrics.avgBottleVolume.map { ("Avg Bottle", "\(String(format: "%.1f", $0)) oz") },
                summary.feedingMetrics.avgNursingDuration.map { ("Avg Nursing", formatDuration($0)) }
            ].compactMap { $0 }
        )
    }

    private var explorerMetricsSection: some View {
        Group {
            if let metrics = summary.explorerMetrics {
                MetricsCard(
                    title: "Food Exploration",
                    icon: "fork.knife.circle.fill",
                    color: .green,
                    metrics: [
                        ("New Foods Tried", "\(metrics.newFoodsTried)"),
                        ("Color Categories", "\(metrics.foodsByColor.count)"),
                        ("Allergen Exposures", metrics.allergenExposures.joined(separator: ", ")),
                        ("Reactions", "\(metrics.allergenReactions)")
                    ]
                )
            }
        }
    }

    private var diaperMetricsSection: some View {
        MetricsCard(
            title: "Diaper Changes",
            icon: "allergens",
            color: .blue,
            metrics: [
                ("Avg Changes/Day", String(format: "%.1f", summary.diaperMetrics.avgChangesPerDay)),
                ("Total Changes", "\(summary.diaperMetrics.totalChanges)"),
                ("Wet Diapers", "\(summary.diaperMetrics.wetDiapers)"),
                ("Dirty Diapers", "\(summary.diaperMetrics.dirtyDiapers)")
            ]
        )
    }

    private var growthMetricsSection: some View {
        Group {
            if let weightChange = summary.growthMetrics?.weightChange,
               let heightChange = summary.growthMetrics?.heightChange,
               weightChange != 0 || heightChange != 0 {
                MetricsCard(
                    title: "Growth",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    metrics: [
                        summary.growthMetrics?.startWeight.map { ("Start Weight", "\(String(format: "%.2f", $0)) kg") },
                        summary.growthMetrics?.endWeight.map { ("End Weight", "\(String(format: "%.2f", $0)) kg") },
                        weightChange != 0 ? ("Weight Change", "\(String(format: "%.2f", weightChange)) kg") : nil,
                        heightChange != 0 ? ("Height Change", "\(String(format: "%.1f", heightChange)) cm") : nil
                    ].compactMap { $0 }
                )
            }
        }
    }

    private var parentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(appState.themeColor)
                Text("Parent Notes")
                    .font(.headline)
                Spacer()
                Button(isEditingNotes ? "Done" : "Edit") {
                    isEditingNotes.toggle()
                }
                .font(.subheadline)
            }

            if isEditingNotes {
                TextEditor(text: Binding(
                    get: { summary.parentNotes ?? "" },
                    set: { summary.parentNotes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(summary.parentNotes ?? "No notes added")
                    .font(.body)
                    .foregroundStyle(summary.parentNotes == nil ? .secondary : .primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func generateShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var text = """
        PEDIATRICIAN VISIT SUMMARY
        \(dateFormatter.string(from: summary.startDate)) - \(dateFormatter.string(from: summary.endDate))

        \(summary.aiSummary)

        """

        if !summary.highlights.isEmpty {
            text += "\nKEY HIGHLIGHTS:\n"
            for (index, highlight) in summary.highlights.enumerated() {
                text += "\(index + 1). \(highlight)\n"
            }
        }

        if !summary.concerns.isEmpty {
            text += "\nCONCERNS:\n"
            for (index, concern) in summary.concerns.enumerated() {
                text += "\(index + 1). \(concern)\n"
            }
        }

        if !summary.suggestedQuestions.isEmpty {
            text += "\nQUESTIONS FOR YOUR PEDIATRICIAN:\n"
            for (index, question) in summary.suggestedQuestions.enumerated() {
                text += "\(index + 1). \(question)\n"
            }
        }

        if let notes = summary.parentNotes, !notes.isEmpty {
            text += "\nPARENT NOTES:\n\(notes)\n"
        }

        return text
    }
}

// MARK: - Metrics Card

struct MetricsCard: View {
    let title: String
    let icon: String
    let color: Color
    let metrics: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            ForEach(metrics, id: \.0) { metric in
                HStack {
                    Text(metric.0)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(metric.1)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
