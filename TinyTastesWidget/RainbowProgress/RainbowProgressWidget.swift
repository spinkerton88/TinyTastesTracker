import WidgetKit
import SwiftUI

struct RainbowProgressWidget: Widget {
    let kind: String = "RainbowProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainbowProgressProvider()) { entry in
            if #available(iOS 17.0, *) {
                RainbowProgressEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(UIColor.systemBackground)
                    }
            } else {
                RainbowProgressEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Rainbow Progress")
        .description("Track your 'Eat the Rainbow' food variety goals.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
