import WidgetKit
import SwiftUI

struct RainbowProgressWidget: Widget {
    let kind: String = "RainbowProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RainbowProgressProvider()) { entry in
            RainbowProgressEntryView(entry: entry)
        }
        .configurationDisplayName("Rainbow Progress")
        .description("Track your 'Eat the Rainbow' food variety goals.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
