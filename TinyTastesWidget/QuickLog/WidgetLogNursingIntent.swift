import AppIntents
import WidgetKit

/// Widget-specific intent for logging nursing sessions via UserDefaults
/// This avoids SwiftData dependencies that aren't available in widget context
struct WidgetLogNursingIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Nursing"
    static var description = IntentDescription("Logs a nursing session from widget.")
    static var openAppWhenRun: Bool = true // Open app to complete the log

    func perform() async throws -> some IntentResult {
        // Set a flag indicating the widget triggered a nursing log
        // The main app will pick this up and create the actual log
        WidgetDataManager.setLogRequest(type: .nursing)
        return .result()
    }
}
