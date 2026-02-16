import WidgetKit
import SwiftUI

struct LastFeedProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lastFeedTime: Date().addingTimeInterval(-3600), feedType: "Nursing")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), lastFeedTime: Date().addingTimeInterval(-3600), feedType: "Nursing")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var lastFeedTime: Date?
            var feedType: String = "Feed"

            // Try fetching from Firestore if authenticated and have active profile
            if WidgetDataManager.isUserAuthenticated(),
               let profileId = WidgetDataManager.getActiveProfileId() {

                // Fetch both bottle and nursing feeds to find most recent
                let bottleFeeds = try? await WidgetDataManager.fetchRecentBottleFeeds(for: profileId, limit: 1)
                let nursingLogs = try? await WidgetDataManager.fetchRecentNursingLogs(for: profileId, limit: 1)

                let latestBottle = bottleFeeds?.first
                let latestNursing = nursingLogs?.first

                // Compare and use most recent
                if let bottle = latestBottle, let nursing = latestNursing {
                    if bottle.timestamp > nursing.timestamp {
                        lastFeedTime = bottle.timestamp
                        feedType = "Bottle"
                    } else {
                        lastFeedTime = nursing.timestamp
                        feedType = "Nursing"
                    }
                } else if let bottle = latestBottle {
                    lastFeedTime = bottle.timestamp
                    feedType = "Bottle"
                } else if let nursing = latestNursing {
                    lastFeedTime = nursing.timestamp
                    feedType = "Nursing"
                }
            }

            // Fallback to UserDefaults if Firestore failed or no data
            if lastFeedTime == nil {
                let sharedDefaults = UserDefaults(suiteName: "group.com.tinytastes.tracker")
                lastFeedTime = sharedDefaults?.object(forKey: "lastFeedTime") as? Date
                feedType = sharedDefaults?.string(forKey: "lastFeedType") ?? "Feed"
            }

            let entry = SimpleEntry(
                date: Date(),
                lastFeedTime: lastFeedTime ?? Date(),
                feedType: feedType
            )

            // Update every 15 minutes to keep "Time Since" somewhat fresh, though `style: .relative` handles display
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastFeedTime: Date
    let feedType: String
}

struct LastFeedWidgetEntryView : View {
    var entry: LastFeedProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(.pink.opacity(0.1))

                VStack(spacing: 0) {
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                    Text(entry.lastFeedTime, style: .relative)
                        .font(.caption2)
                }
            }
        case .accessoryRectangular:
            HStack {
                Image(systemName: "fork.knife")
                    .font(.title3)
                VStack(alignment: .leading) {
                    Text(entry.feedType)
                        .font(.headline)
                    Text(entry.lastFeedTime, style: .relative)
                        .font(.caption)
                }
            }
        case .systemSmall, .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 8, height: 8)
                    Text("Last Feed")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                    
                    Spacer()
                    
                    if family == .systemMedium {
                         Text(entry.lastFeedTime, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                         Text(entry.lastFeedTime, style: .relative)
                            .font(.system(size: 32, weight: .bold))
                            .minimumScaleFactor(0.5)
                        
                        Text(entry.feedType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("ago")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if family == .systemMedium {
                        Spacer()
                        // In medium view, we can put the button on the right
                        if #available(iOS 17.0, *) {
                             Button(intent: WidgetLogBottleIntent()) {
                                Label("Log Bottle", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                            .tint(.pink)
                        }
                    }
                }
                
                if family == .systemSmall {
                    if #available(iOS 17.0, *) {
                        Button(intent: WidgetLogBottleIntent()) {
                             Label("Log Bottle", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.pink)
                    }
                }
            }
            .padding()

        default:
             Text("Last Feed")
        }
    }
}

struct LastFeedWidget: Widget {
    let kind: String = "LastFeedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastFeedProvider()) { entry in
            if #available(iOS 17.0, *) {
                LastFeedWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                         Color(UIColor.secondarySystemBackground)
                    }
            } else {
                LastFeedWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Last Feed")
        .description("See how long it's been since the last feed.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
