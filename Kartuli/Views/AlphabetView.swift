import SwiftUI

struct AlphabetView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var query = ""
    @State private var selectedLetter: GeorgianLetter?
    @State private var isEndlessPresented = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 11), count: 4)
    private var filtered: [GeorgianLetter] {
        guard !query.isEmpty else { return GeorgianLetter.all }
        return GeorgianLetter.all.filter { $0.glyph.contains(query) || $0.name.localizedCaseInsensitiveContains(query) || $0.sound.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("The Georgian alphabet").font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.ink)
                            Text("33 letters · Mkhedruli script").foregroundStyle(AppTheme.secondary)
                        }
                        AlphabetPathSection()
                        endlessCard
                        LazyVGrid(columns: columns, spacing: 11) {
                            ForEach(filtered) { letter in
                                let learned = store.learnedLetterIDs.contains(letter.id)
                                Button { selectedLetter = letter } label: {
                                    VStack(spacing: 3) {
                                        Text(letter.glyph).font(.system(size: 36, weight: .bold))
                                        Text(letter.sound).font(.caption2.bold()).opacity(0.72)
                                    }
                                    .foregroundStyle(learned ? AppTheme.violet : AppTheme.ink)
                                    .frame(maxWidth: .infinity).frame(height: 78)
                                    .glassEffect(learned ? .regular.tint(AppTheme.violet.opacity(0.12)) : .regular, in: .rect(cornerRadius: 20))
                                    .overlay(alignment: .topTrailing) {
                                        if learned { Image(systemName: "checkmark.circle.fill").font(.caption).foregroundStyle(AppTheme.mint).padding(7) }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20).padding(.bottom, 30)
                }
            }
            .searchable(text: $query, prompt: "Letter, name or sound")
            .sheet(item: $selectedLetter) { LetterDetailView(letter: $0) }
            .fullScreenCover(isPresented: $isEndlessPresented) { EndlessPracticeView() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var endlessCard: some View {
        Button {
            if store.isEndlessUnlocked {
                isEndlessPresented = true
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 64, height: 64)
                    Image(systemName: store.isEndlessUnlocked ? "infinity" : "lock.fill")
                        .font(.system(size: 29, weight: .bold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isEndlessUnlocked ? "ENDLESS PRACTICE" : "LOCKED")
                        .font(.caption2.bold()).tracking(1.1).foregroundStyle(AppTheme.yellow)
                    Text(store.isEndlessUnlocked ? "Keep the letters flowing" : "Complete your alphabet path")
                        .font(.headline.bold()).foregroundStyle(.white)
                    Text(store.isEndlessUnlocked ? "High score \(store.endlessBest) · No time limit" : "\(store.learnedLetterIDs.count) of \(GeorgianLetter.all.count) letters learned")
                        .font(.caption).foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: store.isEndlessUnlocked ? "play.fill" : "flag.checkered")
                    .foregroundStyle(AppTheme.onLightSurface).padding(13).background(.white, in: Circle())
            }
            .padding(18)
            .background(LinearGradient(colors: [AppTheme.violet, AppTheme.blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 27, style: .continuous))
            .shadow(color: AppTheme.violet.opacity(0.22), radius: 16, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct LetterDetailView: View {
    let letter: GeorgianLetter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 24) {
                HStack { Spacer(); Button("Done") { dismiss() }.font(.headline).foregroundStyle(AppTheme.coral) }
                Text(letter.glyph).font(.system(size: 130, weight: .bold)).foregroundStyle(AppTheme.violet)
                VStack(spacing: 7) {
                    Text(letter.name.capitalized).font(.title.bold()).foregroundStyle(AppTheme.ink)
                    Text("Sounds like “\(letter.sound)”").foregroundStyle(AppTheme.secondary)
                }
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(letter.example).font(.title2.bold()).foregroundStyle(AppTheme.ink)
                            Text(letter.translation.capitalized).foregroundStyle(AppTheme.secondary)
                        }
                        Spacer()
                        Image(systemName: "text.book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.coral)
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
