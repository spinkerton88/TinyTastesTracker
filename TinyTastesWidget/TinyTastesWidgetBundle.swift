import WidgetKit
import SwiftUI

@main
struct TinyTastesWidgetBundle: WidgetBundle {
    var body: some Widget {
        LastFeedWidget()
        SleepTimerActivity()
        QuickLogWidget()
        RainbowProgressWidget()

    }
}
