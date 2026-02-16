import WidgetKit
import SwiftUI

struct SleepSweetSpotWidget: Widget {
    let kind: String = "SleepSweetSpotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepSweetSpotProvider()) { entry in
            if #available(iOS 17.0, *) {
                SleepSweetSpotEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                         Color(UIColor.systemBackground)
                    }
            } else {
                SleepSweetSpotEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Sleep Sweet Spot")
        .description("Countdown to your baby's predicted optimal sleep window.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
