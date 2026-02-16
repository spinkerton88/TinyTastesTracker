import AppIntents
import Foundation

struct LogBottleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Bottle"
    static var description = IntentDescription("Logs a bottle feed.")
    static var openAppWhenRun: Bool = false // Runs in background

    @Parameter(title: "Amount (oz)", default: 4.0)
    var amount: Double
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Re-implement intent with new data model
        return .result(value: "Log Bottle Intent needs update")
    }
}
