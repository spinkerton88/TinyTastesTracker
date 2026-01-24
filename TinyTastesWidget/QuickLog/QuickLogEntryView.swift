import WidgetKit
import SwiftUI
import AppIntents

struct QuickLogEntryView: View {
    var entry: QuickLogProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumWidgetView
        case .systemLarge:
            largeWidgetView
        default:
            // Quick Log widget only supports medium and large
            Text("Quick Log")
                .font(.caption)
        }
    }

    // MARK: - Medium Widget (2x2 grid)

    private var mediumWidgetView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(Color.indigo)
                    .frame(width: 8, height: 8)
                Text("Quick Log")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.indigo)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // 2x2 Button Grid
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    logButton(
                        icon: "drop.fill",
                        label: "Bottle",
                        lastTime: entry.lastBottleTime,
                        color: .pink,
                        intent: WidgetLogBottleIntent()
                    )
                    logButton(
                        icon: "figure.walk",
                        label: "Nursing",
                        lastTime: entry.lastNursingTime,
                        color: .purple,
                        intent: WidgetLogNursingIntent()
                    )
                }
                HStack(spacing: 8) {
                    logButton(
                        icon: "sage.leaf.sprig",
                        label: "Diaper",
                        lastTime: entry.lastDiaperTime,
                        color: .orange,
                        intent: WidgetLogDiaperIntent()
                    )
                    logButton(
                        icon: "moon.fill",
                        label: "Sleep",
                        lastTime: entry.lastSleepTime,
                        color: .blue,
                        intent: WidgetLogSleepIntent()
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Large Widget (3x2 grid)

    private var largeWidgetView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(Color.indigo)
                    .frame(width: 10, height: 10)
                Text("Quick Log")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.indigo)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // 3x2 Button Grid
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    logButton(
                        icon: "drop.fill",
                        label: "Bottle",
                        lastTime: entry.lastBottleTime,
                        color: .pink,
                        intent: WidgetLogBottleIntent(),
                        isLarge: true
                    )
                    logButton(
                        icon: "figure.walk",
                        label: "Nursing",
                        lastTime: entry.lastNursingTime,
                        color: .purple,
                        intent: WidgetLogNursingIntent(),
                        isLarge: true
                    )
                    logButton(
                        icon: "sage.leaf.sprig",
                        label: "Diaper",
                        lastTime: entry.lastDiaperTime,
                        color: .orange,
                        intent: WidgetLogDiaperIntent(),
                        isLarge: true
                    )
                }
                HStack(spacing: 10) {
                    logButton(
                        icon: "moon.fill",
                        label: "Sleep",
                        lastTime: entry.lastSleepTime,
                        color: .blue,
                        intent: WidgetLogSleepIntent(),
                        isLarge: true
                    )
                    logButton(
                        icon: "fork.knife",
                        label: "Meal",
                        lastTime: nil,
                        color: .green,
                        intent: WidgetLogBottleIntent(), // Placeholder
                        isLarge: true
                    )
                    logButton(
                        icon: "figure.child",
                        label: "Growth",
                        lastTime: nil,
                        color: .cyan,
                        intent: WidgetLogBottleIntent(), // Placeholder
                        isLarge: true
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Button Component

    private func logButton<Intent: AppIntent>(
        icon: String,
        label: String,
        lastTime: Date?,
        color: Color,
        intent: Intent,
        isLarge: Bool = false
    ) -> some View {
        Button(intent: intent) {
            VStack(spacing: isLarge ? 8 : 4) {
                // Use custom asset if it's sage.leaf.sprig, otherwise use SF Symbol
                if icon == "sage.leaf.sprig" {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isLarge ? 28 : 24, height: isLarge ? 28 : 24)
                        .foregroundStyle(color)
                } else {
                    Image(systemName: icon)
                        .font(isLarge ? .title2 : .title3)
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(isLarge ? .caption : .caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let lastTime = lastTime {
                    Text(lastTime, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
