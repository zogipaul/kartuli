import SwiftUI
import WidgetKit

private enum SharedStreak {
    static let appGroupID = "group.com.example.kartuli"
    static let key = "sharedStreak"

    static var value: Int {
        UserDefaults(suiteName: appGroupID)?.integer(forKey: key) ?? 0
    }
}

private struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

private struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), streak: context.isPreview ? 7 : SharedStreak.value))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: Date(), streak: SharedStreak.value)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        HStack(spacing: family == .systemSmall ? 0 : 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("KARTULI", systemImage: "character.book.closed.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.78))

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.16))
                    Text("\(entry.streak)")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("day streak")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }

            if family != .systemSmall {
                Spacer()
                Image(systemName: "textformat.characters")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
        .containerBackground(
            LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 0.96),
                    Color(red: 0.23, green: 0.58, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

@main
struct KartuliStreakWidget: Widget {
    let kind = "KartuliStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Kartuli Streak")
        .description("See your current Georgian learning streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
