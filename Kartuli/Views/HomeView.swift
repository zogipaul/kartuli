import SwiftUI

struct HomeView: View {
    @Environment(LearningStore.self) private var store
    @AppStorage("profileAvatar") private var selectedAvatarID = ProfileAvatar.khinkali.rawValue
    @State private var isEndlessPresented = false
    @State private var isWordPracticePresented = false

    private var selectedAvatar: ProfileAvatar {
        ProfileAvatar(rawValue: selectedAvatarID) ?? .khinkali
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        hero
                        stats
                        if store.isEndlessUnlocked {
                            practiceModes
                        } else {
                            nextUp
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isEndlessPresented) {
                EndlessPracticeView()
            }
            .fullScreenCover(isPresented: $isWordPracticePresented) {
                WordPracticeView()
            }
        }
    }

    private var header: some View {
        HStack {
            TimelineView(.everyMinute) { context in
                let greeting = DayGreeting(date: context.date)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: greeting.georgian).font(.title2.bold()).foregroundStyle(AppTheme.ink)
                    Text("\(Text(verbatim: greeting.transliteration).italic()) · \(Text(greeting.meaning))")
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            Spacer()
            ProfileAvatarImage(avatar: selectedAvatar, size: 50)
                .accessibilityHidden(true)
        }
        .padding(.top, 12)
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AppTheme.heroGradient)
            Circle().fill(.white.opacity(0.1)).frame(width: 180).offset(x: 65, y: -70)
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Label { Text(store.todayLabel) } icon: { Image(systemName: "flame.fill") }
                        .font(.caption.bold()).foregroundStyle(AppTheme.yellow)
                    Spacer()
                    Text("\(store.dailyProgress)/\(store.streakXPThreshold) XP")
                        .font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                }
                Text(verbatim: store.welcomeMessage)
                    .scaledFont(29, weight: .heavy, design: .rounded, relativeTo: .title)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: Double(store.dailyProgress), total: Double(store.streakXPThreshold))
                    .tint(AppTheme.yellow).background(.white.opacity(0.2)).clipShape(.capsule)
                    .accessibilityLabel("Daily goal")
                Button {
                    if store.isEndlessUnlocked {
                        isWordPracticePresented = true
                    } else {
                        store.isLessonPresented = true
                    }
                } label: {
                    HStack {
                        Text(store.isEndlessUnlocked ? "Build your first words" : "Continue lesson")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(AppTheme.onLightSurface)
                    .font(.headline.bold())
                    .padding(.horizontal, 18).padding(.vertical, 15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: AppTheme.violet.opacity(0.24), radius: 22, y: 12)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatCard(icon: "flame.fill", value: "\(store.streak)", label: "day streak", color: AppTheme.coral)
            StatCard(icon: "bolt.fill", value: "\(store.xp)", label: "total XP", color: AppTheme.yellow)
            StatCard(icon: "character.book.closed.fill", value: "\(store.learnedLetterIDs.count)", label: "letters", color: AppTheme.mint)
        }
    }

    private var nextUp: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Next up").font(.title3.bold()).foregroundStyle(AppTheme.ink)
                Spacer()
                Button("View path") { store.selectedTab = .learn }.font(.subheadline.bold()).foregroundStyle(AppTheme.coral)
            }
            Button { store.isLessonPresented = true } label: {
                GlassCard {
                    HStack(spacing: 16) {
                        Text(verbatim: store.nextLetters.first?.glyph ?? "ა")
                            .scaledFont(42, relativeTo: .title, maxSize: 64)
                            .foregroundStyle(AppTheme.coral)
                            .frame(minWidth: 72, minHeight: 72)
                            .background(AppTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Three new letters").font(.headline).foregroundStyle(AppTheme.ink)
                            Text(verbatim: store.nextLetters.map(\.glyph).joined(separator: "  "))
                                .font(.title2.bold()).foregroundStyle(AppTheme.violet)
                                .accessibilityLabel(store.nextLetters.map(\.name).joined(separator: ", "))
                            Label("About 4 min", systemImage: "clock").font(.caption).foregroundStyle(AppTheme.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(AppTheme.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            LockedModeCard(eyebrow: "ENDLESS MODE", title: "Locked for now",
                           subtitle: "Finish the alphabet path to unlock",
                           symbol: "infinity", tint: AppTheme.violet)
            LockedModeCard(eyebrow: "FIRST WORDS", title: "Your next learning step",
                           subtitle: "Finish the alphabet, then start reading",
                           symbol: "textformat.abc", tint: AppTheme.coral)
        }
    }

    private var practiceModes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Keep learning")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
            WordPracticeCard { isWordPracticePresented = true }
            EndlessPracticeCard { isEndlessPresented = true }
        }
    }
}

/// Opens First Words; shared by Today and Learn.
struct WordPracticeCard: View {
    @Environment(LearningStore.self) private var store
    let action: () -> Void

    var body: some View {
        ModeCard(icon: "textformat.abc", eyebrow: "FIRST WORDS", title: "Build words from letters",
                 subtitle: "\(store.masteredWordIDs.count) of \(GeorgianWord.all.count) words learned",
                 gradient: AppTheme.wordsGradient, shadow: AppTheme.coral, action: action)
    }
}

/// Opens Endless Mode; shared by Today and Learn.
struct EndlessPracticeCard: View {
    @Environment(LearningStore.self) private var store
    let action: () -> Void

    var body: some View {
        ModeCard(icon: "infinity", eyebrow: "ENDLESS MODE", title: "Keep the letters flowing",
                 subtitle: "High score \(store.endlessBest) · No time limit", trailingIcon: "play.fill",
                 gradient: AppTheme.endlessGradient, shadow: AppTheme.violet, action: action)
    }
}
