import AppIntents
import WidgetKit

/// Widget-specific intent for logging sleep via UserDefaults
/// This avoids SwiftData dependencies that aren't available in widget context
struct WidgetLogSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Sleep"
    static var description = IntentDescription("Logs sleep from widget.")
    static var openAppWhenRun: Bool = true // Open app to complete the log

    func perform() async throws -> some IntentResult {
        // Set a flag indicating the widget triggered a sleep log
        // The main app will pick this up and create the actual log
        WidgetDataManager.setLogRequest(type: .sleep)
        return .result()
    }
}
