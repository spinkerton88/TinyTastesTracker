import WidgetKit
import SwiftUI

struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
            QuickLogEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("One-tap logging for bottle, nursing, diaper, and sleep.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
