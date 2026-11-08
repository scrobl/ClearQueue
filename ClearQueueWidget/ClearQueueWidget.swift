import WidgetKit
import SwiftUI
import AppIntents

struct ClearEntry: TimelineEntry { let date: Date }

struct ClearProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClearEntry { ClearEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (ClearEntry) -> Void) { completion(ClearEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClearEntry>) -> Void) {
        completion(Timeline(entries: [ClearEntry(date: .now)], policy: .never))
    }
}

struct ClearQueueWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Button(intent: ClearQueueIntent()) {
            switch family {
            case .accessoryCircular:
                Image(systemName: "text.badge.xmark").font(.title2)
            case .accessoryRectangular:
                Label("Clear Queue", systemImage: "text.badge.xmark").font(.headline)
            default:
                VStack(spacing: 10) {
                    Image(systemName: "text.badge.xmark").font(.system(size: 40, weight: .semibold))
                    Text("Clear Queue").font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 1, green: 0.35, blue: 0.5), Color(red: 1, green: 0.5, blue: 0.25)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct ClearQueueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClearQueueWidget", provider: ClearProvider()) { _ in
            ClearQueueWidgetView()
        }
        .configurationDisplayName("Clear Queue")
        .description("Clears the Apple Music queue, keeping the current song.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct ClearQueueWidgetBundle: WidgetBundle {
    var body: some Widget { ClearQueueWidget() }
}
