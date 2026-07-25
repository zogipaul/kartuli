import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: LearningStore
    @AppStorage("profileAvatar") private var selectedAvatarID = ProfileAvatar.khinkali.rawValue
    @State private var isEndlessPresented = false

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
                            endlessMode
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
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("დილა მშვიდობისა!").font(.title2.bold()).foregroundStyle(AppTheme.ink)
                Text("Good morning, learner").font(.subheadline).foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            ProfileAvatarImage(avatar: selectedAvatar, size: 50)
        }
        .padding(.top, 12)
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [AppTheme.violet, Color(red: 0.35, green: 0.28, blue: 0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(.white.opacity(0.1)).frame(width: 180).offset(x: 65, y: -70)
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Label(store.todayLabel, systemImage: "flame.fill")
                        .font(.caption.bold()).foregroundStyle(AppTheme.yellow)
                    Spacer()
                    Text("\(store.dailyProgress)/\(store.streakXPThreshold) XP")
                        .font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                }
                Text("Ready for your\nGeorgian moment?")
                    .font(.system(size: 29, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                ProgressView(value: Double(store.dailyProgress), total: Double(store.streakXPThreshold))
                    .tint(AppTheme.yellow).background(.white.opacity(0.2)).clipShape(.capsule)
                Button {
                    if store.isEndlessUnlocked {
                        isEndlessPresented = true
                    } else {
                        store.isLessonPresented = true
                    }
                } label: {
                    HStack {
                        Text(store.isEndlessUnlocked ? "Start endless mode" : "Continue lesson")
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
                Button("View path") { store.selectedTab = 1 }.font(.subheadline.bold()).foregroundStyle(AppTheme.coral)
            }
            GlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20).fill(AppTheme.coral.opacity(0.12)).frame(width: 72, height: 72)
                        Text(store.nextLetters.first?.glyph ?? "ა").font(.system(size: 42, weight: .bold)).foregroundStyle(AppTheme.coral)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Three new letters").font(.headline).foregroundStyle(AppTheme.ink)
                        Text(store.nextLetters.map(\.glyph).joined(separator: "  ")).font(.title2.bold()).foregroundStyle(AppTheme.violet)
                        Label("About 4 min", systemImage: "clock").font(.caption).foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(AppTheme.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { store.isLessonPresented = true }
            }
            lockedEndlessMode
        }
    }

    private var lockedEndlessMode: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.violet.opacity(0.12))
                    .frame(width: 62, height: 62)
                Image(systemName: "lock.fill")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(AppTheme.violet)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ENDLESS MODE")
                    .font(.caption2.bold())
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.violet)
                Text("Locked for now")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.ink)
                Text("Finish the current path to unlock")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            Image(systemName: "infinity")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.secondary.opacity(0.65))
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 27))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Endless Mode. Locked for now. Finish the current path to unlock.")
    }

    private var endlessMode: some View {
        Button { isEndlessPresented = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 62, height: 62)
                    Image(systemName: "infinity")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENDLESS MODE")
                        .font(.caption2.bold())
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.yellow)
                    Text("High score \(store.endlessBest)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("All letters · No time limit")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
                Image(systemName: "play.fill")
                    .foregroundStyle(AppTheme.onLightSurface)
                    .padding(13)
                    .background(.white, in: Circle())
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [AppTheme.violet, AppTheme.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 27, style: .continuous)
            )
            .shadow(color: AppTheme.violet.opacity(0.22), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title3.bold()).foregroundStyle(AppTheme.ink)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}
