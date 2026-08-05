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
        Group {
            if family == .systemSmall {
                smallWidget
            } else {
                mediumWidget
            }
        }
        .containerBackground(widgetBackground, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Kartuli, \(entry.streak) day streak")
    }

    private var smallWidget: some View {
        ZStack(alignment: .topTrailing) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(.white.opacity(0.13))
                    .frame(width: 64, height: 64)
                mascot(width: 68)
                    .rotationEffect(.degrees(-5))
                    .offset(x: 7, y: 4)
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.16))
                    .offset(x: -55, y: 1)
            }
            .offset(x: 8, y: 18)
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 14) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            ZStack(alignment: .bottom) {
                Circle()
                    .fill(.white.opacity(0.12))
                    .overlay {
                        Circle().stroke(.white.opacity(0.16), lineWidth: 1)
                    }
                    .frame(width: 128, height: 128)

                mascot(width: 128)
                    .rotationEffect(.degrees(-4))
                    .offset(y: -5)

                Text(entry.streak == 0 ? "Let’s begin!" : "Keep it up!")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.37))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.94), in: Capsule())
                    .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
                    .offset(y: 3)
            }
            .frame(width: 145)
            .frame(maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Image(systemName: "sparkles")
                    .font(.headline.bold())
                    .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.16))
                    .offset(x: 5, y: 2)
            }
        }
    }

    private func mascot(width: CGFloat) -> some View {
        Image("WidgetKhinkali")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: .black.opacity(0.17), radius: 8, y: 5)
    }

    private var widgetBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.49, green: 0.34, blue: 0.96),
                Color(red: 0.23, green: 0.58, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
