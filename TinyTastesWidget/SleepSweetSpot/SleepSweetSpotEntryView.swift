import WidgetKit
import SwiftUI
import AppIntents

struct SleepSweetSpotEntryView: View {
    var entry: SleepSweetSpotProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            Text("Sleep Sweet Spot")
                .font(.caption)
        }
    }

    // MARK: - Small Widget

    private var smallWidgetView: some View {
        VStack(spacing: 12) {
            if entry.isSleepActive {
                sleepActiveView
            } else if entry.isStale {
                staleView
            } else if let timeUntil = entry.timeUntilSweetSpot {
                countdownView(timeUntil: timeUntil, isCompact: true)
            } else {
                noPredictionView
            }
        }
        .padding()
        .background {
            if #unavailable(iOS 17.0) {
                Color(UIColor.systemBackground)
            }
        }
    }

    // MARK: - Medium Widget

    private var mediumWidgetView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text("Sleep Sweet Spot")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Content
            if entry.isSleepActive {
                sleepActiveViewMedium
            } else if entry.isStale {
                staleViewMedium
            } else if let timeUntil = entry.timeUntilSweetSpot {
                countdownViewMedium(timeUntil: timeUntil)
            } else {
                noPredictionViewMedium
            }
        }
        .background {
            if #unavailable(iOS 17.0) {
                Color(UIColor.systemBackground)
            }
        }
    }

    // MARK: - Accessory Rectangular

    private var accessoryRectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.fill")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Spot")
                    .font(.headline)

                if entry.isSleepActive {
                    Text("In progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let timeUntil = entry.timeUntilSweetSpot {
                    Text("In \(formatTime(timeUntil))")
                        .font(.caption)
                } else {
                    Text("Tap to refresh")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
    }

    // MARK: - State Views (Small)

    private var sleepActiveView: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("Sleep in Progress")
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            if let startTime = entry.activeSleepStartTime {
                Text(startTime, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var staleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Tap to Refresh")
                .font(.caption)
                .fontWeight(.semibold)

            Text("Prediction expired")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func countdownView(timeUntil: TimeInterval, isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text(formatTime(timeUntil))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text("until sweet spot")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var noPredictionView: some View {
        VStack(spacing: 8) {
            Image("sage.leaf.sprig")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("Open app")
                .font(.caption)
                .fontWeight(.semibold)

            Text("to get prediction")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - State Views (Medium)

    private var sleepActiveViewMedium: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep in Progress")
                        .font(.headline)

                    if let startTime = entry.activeSleepStartTime {
                        Text("Started \(startTime, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            Text("Active sleep timer running. Check Live Activity for details.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    private var staleViewMedium: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Prediction Expired")
                .font(.headline)

            Button(intent: WidgetStartSleepIntent()) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Open App to Refresh")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
    }

    private func countdownViewMedium(timeUntil: TimeInterval) -> some View {
        VStack(spacing: 12) {
            // Countdown display
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)

                    Text("Next Window")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(formatTime(timeUntil))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    if let confidence = entry.prediction?.confidence {
                        Text(confidence)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Start sleep button
            Button(intent: WidgetStartSleepIntent()) {
                HStack {
                    Image(systemName: "moon.fill")
                    Text("Start Sleep Now")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var noPredictionViewMedium: some View {
        VStack(spacing: 16) {
            Image("sage.leaf.sprig")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("No Prediction Available")
                .font(.headline)

            Button(intent: WidgetStartSleepIntent()) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Open App for Prediction")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
