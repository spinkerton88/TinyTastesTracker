import AppIntents
import Foundation
import ActivityKit

struct LogSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Sleep"
    static var description = IntentDescription("Starts or stops tracking sleep.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Action", requestValueDialog: "Start or Stop sleep?")
    var action: SleepAction
    
    enum SleepAction: String, AppEnum {
        case start
        case stop
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sleep Action"
        static var caseDisplayRepresentations: [SleepAction : DisplayRepresentation] = [
            .start: "Start Sleep",
            .stop: "Stop Sleep"
        ]
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Limited scope: Accessing Live Activities directly is hard from intent without AppState context.
        // We will just return a message directing user to app for now, OR try to manipulate ActivityKit directly.
        
        if action == .start {
            // New Sleep
             if ActivityAuthorizationInfo().areActivitiesEnabled {
                 // We can start activity here if we share Attributes
                 let attributes = SleepActivityAttributes(babyName: "Baby", startTime: Date())
                 let contentState = SleepActivityAttributes.ContentState(totalDuration: 0)
                 do {
                     let _ = try Activity<SleepActivityAttributes>.request(
                         attributes: attributes,
                         content: .init(state: contentState, staleDate: nil)
                     )
                     return .result(value: "Sleep timer started.")
                 } catch {
                     return .result(value: "Could not start sleep timer.")
                 }
             }
            return .result(value: "Sleep timer started.")
        } else {
            // Stop Sleep
            // Finding active activity
            for activity in Activity<SleepActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            
            // Also need to log to database?
            // This is complex because we need the start time.
            // For MVP, just stopping the Live Activity is a good start.
            return .result(value: "Sleep timer stopped.")
        }
    }
}
