import AppIntents

struct TinyTastesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogBottleIntent(),
            phrases: [
                "Log a bottle in \(.applicationName)",
                "Track bottle in \(.applicationName)"
            ],
            shortTitle: "Log Bottle",
            systemImageName: "bottle.fill"
        )
        
        AppShortcut(
            intent: LogSleepIntent(),
            phrases: [
                "Start sleep timer in \(.applicationName)",
                "Baby is asleep in \(.applicationName)"
            ],
            shortTitle: "Start Sleep",
            systemImageName: "moon.stars.fill"
        )
    }
}
