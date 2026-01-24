import AppIntents
import WidgetKit

/// Widget-specific intent for starting sleep tracking
/// Opens the app to begin a sleep session
struct WidgetStartSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep"
    static var description = IntentDescription("Opens app to start tracking sleep.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // The app will handle showing the sleep tracking interface
        // No need to set flags - just opening the app is sufficient
        return .result()
    }
}
