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
        // Fetch from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.tinytastes.tracker")
        let lastFeedTime = sharedDefaults?.object(forKey: "lastFeedTime") as? Date ?? Date()
        let feedType = sharedDefaults?.string(forKey: "lastFeedType") ?? "Feed"
        
        let entry = SimpleEntry(date: Date(), lastFeedTime: lastFeedTime, feedType: feedType)
        
        // Update every 15 minutes to keep "Time Since" somewhat fresh, though `style: .relative` handles display
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text(entry.lastFeedTime, style: .relative)
                        .font(.caption2)
                }
            }
        case .accessoryRectangular:
            HStack {
                Image(systemName: "drop.fill")
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
            .containerBackground(for: .widget) {
                Color(UIColor.secondarySystemBackground)
            }
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
