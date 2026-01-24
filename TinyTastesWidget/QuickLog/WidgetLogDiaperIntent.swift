import AppIntents
import WidgetKit

/// Widget-specific intent for logging diaper changes via UserDefaults
/// This avoids SwiftData dependencies that aren't available in widget context
struct WidgetLogDiaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Diaper"
    static var description = IntentDescription("Logs a diaper change from widget.")
    static var openAppWhenRun: Bool = true // Open app to complete the log

    func perform() async throws -> some IntentResult {
        // Set a flag indicating the widget triggered a diaper log
        // The main app will pick this up and create the actual log
        WidgetDataManager.setLogRequest(type: .diaper)
        return .result()
    }
}
