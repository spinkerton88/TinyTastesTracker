import WidgetKit
import SwiftUI

struct RainbowProgressEntryView: View {
    var entry: RainbowProgressProvider.Entry
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
            Text("Rainbow Progress")
                .font(.caption)
        }
    }

    // MARK: - Small Widget (Circular Ring)

    private var smallWidgetView: some View {
        VStack(spacing: 12) {
            // Circular ring showing progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(entry.achievedColorCount) / CGFloat(entry.totalColorGoal))
                    .stroke(
                        AngularGradient(
                            colors: rainbowGradient,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text("\(entry.achievedColorCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("/ \(entry.totalColorGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Label
            Text("Colors")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Medium Widget (Horizontal Bars)

    private var mediumWidgetView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rainbowGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 8, height: 8)
                Text("Eat the Rainbow")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: rainbowGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                Text("\(entry.achievedColorCount)/\(entry.totalColorGoal)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Progress bars
            VStack(spacing: 6) {
                ForEach(entry.colorProgress) { progress in
                    colorProgressBar(progress: progress)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.systemBackground))
    }

    private func colorProgressBar(progress: ColorProgressData) -> some View {
        HStack(spacing: 8) {
            // Color indicator
            Circle()
                .fill(colorForFoodColor(progress.color))
                .frame(width: 12, height: 12)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForFoodColor(progress.color))
                        .frame(width: geometry.size.width * min(progress.percentage, 1.0))
                }
            }
            .frame(height: 8)

            // Count
            Text("\(progress.count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(progress.metGoal ? .primary : .secondary)
                .frame(width: 16, alignment: .trailing)
        }
    }

    // MARK: - Accessory Rectangular (7-dot indicators)

    private var accessoryRectangularView: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rainbow")
                    .font(.headline)
                Text("\(entry.achievedColorCount)/\(entry.totalColorGoal) colors")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Color dots
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    ForEach(entry.colorProgress.prefix(4)) { progress in
                        colorDot(progress: progress)
                    }
                }
                HStack(spacing: 3) {
                    ForEach(entry.colorProgress.dropFirst(4)) { progress in
                        colorDot(progress: progress)
                    }
                    // Spacer dot if less than 7
                    if entry.colorProgress.count < 7 {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(8)
    }

    private func colorDot(progress: ColorProgressData) -> some View {
        Circle()
            .fill(progress.metGoal ? colorForFoodColor(progress.color) : Color.gray.opacity(0.3))
            .frame(width: 8, height: 8)
    }

    // MARK: - Helpers

    private var rainbowGradient: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    }

    private func colorForFoodColor(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "purple":
            return .purple
        case "white":
            return .gray
        case "brown":
            return .brown
        default:
            return .gray
        }
    }
}
