import SwiftUI
import Observation

@MainActor
@Observable
class NewbornDashboardViewModel {
    // MARK: - Dependencies
    var appState: AppState // Needs to be accessible

    // MARK: - State
    var currentTime: Date = Date()
    var feedIntervalHours: Double {
        didSet {
            UserDefaults.standard.set(feedIntervalHours, forKey: "feed_interval_hours")
            appState.rescheduleFeedNotification()
        }
    }
    var isSleeping: Bool = false

    // MARK: - Private
    private var updateTask: Task<Void, Never>?

    // MARK: - Init
    init(appState: AppState) {
        self.appState = appState
        let savedInterval = UserDefaults.standard.double(forKey: "feed_interval_hours")
        self.feedIntervalHours = savedInterval == 0 ? 3.0 : savedInterval

        setupSmartUpdates()
        updateStatus()
    }

    deinit {
        // Cancel task in nonisolated context
        let task = updateTask
        Task { @MainActor in
            task?.cancel()
        }
    }

    private func setupSmartUpdates() {
        updateTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                // Calculate next values
                let newTime = Date()
                let newIsSleeping = WidgetDataManager.activeSleepStartTime() != nil

                // Only update if values actually changed
                if self.currentTime.formatted(date: .omitted, time: .shortened) != newTime.formatted(date: .omitted, time: .shortened) {
                    self.currentTime = newTime
                }

                if self.isSleeping != newIsSleeping {
                    self.isSleeping = newIsSleeping
                }

                // Sleep until next minute boundary for efficiency
                let now = Date()
                let calendar = Calendar.current
                let currentSecond = calendar.component(.second, from: now)
                let secondsUntilNextMinute = 60 - currentSecond

                do {
                    try await Task.sleep(for: .seconds(secondsUntilNextMinute))
                } catch {
                    // Task was cancelled, exit gracefully
                    break
                }
            }
        }
    }

    func updateStatus() {
        self.currentTime = Date()
        self.isSleeping = WidgetDataManager.activeSleepStartTime() != nil
    }
    
    // MARK: - Computed Logic
    
    var formattedCurrentDate: String {
        currentTime.formatted(date: .numeric, time: .omitted)
    }
    
    var lastFedString: String {
        guard let last = appState.bottleFeedLogs.first else { return "Ready" }
        return last.timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var lastDiaperString: String {
        guard let last = appState.diaperLogs.first else { return "Ready" }
        return last.timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var nextFeedTime: String {
        let lastBottle = appState.bottleFeedLogs.first
        let lastNursing = appState.nursingLogs.first
        
        var lastTime: Date?
        if let b = lastBottle, let n = lastNursing {
            lastTime = b.timestamp > n.timestamp ? b.timestamp : n.timestamp
        } else {
            lastTime = lastBottle?.timestamp ?? lastNursing?.timestamp
        }
        
        guard let last = lastTime else { return "Ready" }
        let next = last.addingTimeInterval(feedIntervalHours * 3600)
        return next.formatted(date: .omitted, time: .shortened)
    }
    
    var babyStatusText: String {
        if isSleeping {
            return "Sleeping"
        }
        
        if let lastSleep = appState.sleepLogs.first {
            if lastSleep.endTime > currentTime {
                return "Sleeping"
            } else {
                return "Awake"
            }
        }
        return "Awake"
    }
    
    var babyStatusIcon: String {
        babyStatusText == "Sleeping" ? "moon.fill" : "sun.max.fill"
    }
    
    var babyStatusColor: Color {
        babyStatusText == "Sleeping" ? .indigo : .yellow
    }
    
    func formatInterval(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)h \(m)m"
        }
    }
}
