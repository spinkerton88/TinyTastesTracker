import WidgetKit
import SwiftUI

struct SleepSweetSpotWidget: Widget {
    let kind: String = "SleepSweetSpotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepSweetSpotProvider()) { entry in
            SleepSweetSpotEntryView(entry: entry)
        }
        .configurationDisplayName("Sleep Sweet Spot")
        .description("Countdown to your baby's predicted optimal sleep window.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
