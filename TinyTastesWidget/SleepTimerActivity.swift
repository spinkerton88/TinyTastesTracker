import ActivityKit
import WidgetKit
import SwiftUI

struct SleepTimerActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            // Lock Screen/Banner UI
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.indigo)
                    Text("\(context.attributes.babyName) is sleeping")
                        .font(.headline)
                    Spacer()
                    Text(context.attributes.startTime, style: .timer)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(.indigo)
                }
                
                ProgressView(timerInterval: context.attributes.startTime...Date().addingTimeInterval(12*3600), countsDown: false)
                    .tint(.indigo)
            }
            .padding()
            .activityBackgroundTint(.white.opacity(0.9)) // Adaptive
            .activitySystemActionForegroundColor(.indigo)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label("Sleep", systemImage: "moon.fill")
                        .foregroundStyle(.indigo)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startTime, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.indigo)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.babyName) has been sleeping for")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // Optional: graphical visualizer
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.indigo)
            } compactTrailing: {
                Text(context.attributes.startTime, style: .timer)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.indigo)
            }
        }
    }
}
