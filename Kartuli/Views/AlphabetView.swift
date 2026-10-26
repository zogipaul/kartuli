import SwiftUI

/// Alphabet: a reference for looking up any letter.
struct AlphabetView: View {
    @Environment(LearningStore.self) private var store
    @State private var query = ""
    @State private var selectedLetter: GeorgianLetter?
    @ScaledMetric(relativeTo: .title) private var tileWidth: CGFloat = 72

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: tileWidth), spacing: 11)]
    }

    private var filtered: [GeorgianLetter] {
        guard !query.isEmpty else { return GeorgianLetter.all }
        return GeorgianLetter.all.filter {
            $0.glyph.contains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
                || $0.sound.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("The Georgian alphabet")
                                .scaledFont(30, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                                .foregroundStyle(AppTheme.ink)
                            Text("33 letters · Mkhedruli script · \(store.learnedLetterIDs.count) learned")
                                .foregroundStyle(AppTheme.secondary)
                        }
                        LazyVGrid(columns: columns, spacing: 11) {
                            ForEach(filtered) { letter in
                                letterTile(letter)
                            }
                        }
                        if filtered.isEmpty {
                            ContentUnavailableView.search(text: query)
                        }
                        Text("An apostrophe marks an ejective sound: say it with a short, popped burst and no puff of air.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    .padding(20).padding(.bottom, 30)
                }
            }
            .searchable(text: $query, prompt: "Letter, name or sound")
            .sheet(item: $selectedLetter) { LetterDetailView(letter: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func letterTile(_ letter: GeorgianLetter) -> some View {
        let learned = store.learnedLetterIDs.contains(letter.id)
        return Button { selectedLetter = letter } label: {
            VStack(spacing: 3) {
                Text(verbatim: letter.glyph).scaledFont(36, relativeTo: .title)
                Text(verbatim: letter.sound).font(.caption2.bold()).opacity(0.72)
            }
            .foregroundStyle(learned ? AppTheme.violet : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassEffect(learned ? .regular.tint(AppTheme.violet.opacity(0.12)) : .regular, in: .rect(cornerRadius: 20))
            .overlay(alignment: .topTrailing) {
                if learned {
                    Image(systemName: "checkmark.circle.fill").font(.caption).foregroundStyle(AppTheme.mint).padding(7)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(letter.spokenName))
        .accessibilityValue(learned ? Text("Learned") : Text("New"))
        .accessibilityHint(Text("Sounds like \(letter.sound)"))
    }
}

private struct LetterDetailView: View {
    let letter: GeorgianLetter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 24) {
                    HStack { Spacer(); Button("Done") { dismiss() }.font(.headline).foregroundStyle(AppTheme.coral) }
                    Text(verbatim: letter.glyph)
                        .scaledFont(130, relativeTo: .largeTitle, maxSize: 190)
                        .foregroundStyle(AppTheme.violet)
                        .accessibilityLabel(Text(letter.spokenName))
                    LetterFacts(letter: letter)
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Name, sound and example word; shared by lessons and the alphabet detail.
struct LetterFacts: View {
    let letter: GeorgianLetter

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(verbatim: letter.name.capitalized)
                    .scaledFont(29, design: .rounded, relativeTo: .title)
                    .foregroundStyle(AppTheme.ink)
                Text("Sounds like “\(letter.sound)”").font(.title3).foregroundStyle(AppTheme.secondary)
                if letter.isEjective {
                    Text("Ejective: a short, popped sound without a puff of air.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: letter.example).font(.title2.bold()).foregroundStyle(AppTheme.ink)
                        Text(letter.translation).foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                    Image(systemName: "character.book.closed.fill")
                        .foregroundStyle(AppTheme.coral).font(.title2)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}
