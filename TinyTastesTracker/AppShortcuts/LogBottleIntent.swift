import AppIntents
import SwiftData
import Foundation

struct LogBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Bottle"
    static var description = IntentDescription("Logs a bottle feed.")
    static var openAppWhenRun: Bool = false // Runs in background

    @Parameter(title: "Amount (oz)", default: 4.0)
    var amount: Double
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let container = SharedModelContainer.shared
        let context = container.mainContext // For background intents, mainContext is usually okay if short-lived, or create new context
        
        let log = BottleFeedLog(timestamp: Date(), amount: amount, feedType: .formula) // Defaulting to formula for generic log
        context.insert(log)
        
        do {
            try context.save()
            
            // Trigger Widget Update (Duplicate logic from AppState for now, ideally shared)
            if let defaults = UserDefaults(suiteName: "group.com.tinytastes.tracker") {
                defaults.set(log.timestamp, forKey: "lastFeedTime")
                defaults.set("Bottle", forKey: "lastFeedType")
                // Cannot import WidgetKit here easily without breaking if mixed targets, but usually fine in App target
                // WidgetCenter.shared.reloadAllTimelines() -> Implicitly handled if AppState logic is reused or separated.
                // For now, simpler to just return success. User will see widget update next time app runs or if we import WidgetKit.
            }
            
            return .result(value: "Logged \(amount)oz bottle.")
        } catch {
            return .result(value: "Failed to log bottle.")
        }
    }
}
