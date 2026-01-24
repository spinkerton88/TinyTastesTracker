import AppIntents
import WidgetKit

/// Widget-specific intent for logging bottle feeds via UserDefaults
/// This avoids SwiftData dependencies that aren't available in widget context
struct WidgetLogBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Bottle"
    static var description = IntentDescription("Logs a bottle feed from widget.")
    static var openAppWhenRun: Bool = true // Open app to complete the log
    
    func perform() async throws -> some IntentResult {
        // Set a flag indicating the widget triggered a bottle log
        // The main app will pick this up and create the actual log
        if let defaults = UserDefaults(suiteName: "group.com.tinytastes.tracker") {
            defaults.set(Date(), forKey: "widgetBottleLogRequest")
        }
        return .result()
    }
}
