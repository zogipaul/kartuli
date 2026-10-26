import SwiftUI

/// Learn: the alphabet path first, then practice modes and the word list.
struct LearnPathView: View {
    @Environment(LearningStore.self) private var store
    @State private var query = ""
    @State private var isWordPracticePresented = false
    @State private var isEndlessPresented = false

    private var filteredWords: [GeorgianWord] {
        guard !query.isEmpty else { return GeorgianWord.all }
        return GeorgianWord.all.filter {
            $0.text.contains(query)
                || $0.transliteration.localizedCaseInsensitiveContains(query)
                || String(localized: $0.translation).localizedCaseInsensitiveContains(query)
                || String(localized: $0.category.title).localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        let wordsByCategory = Dictionary(grouping: filteredWords, by: \.category)
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        if query.isEmpty {
                            header
                            AlphabetPathSection()
                            practice
                        }
                        wordsHeader
                        ForEach(WordCategory.allCases, id: \.self) { category in
                            if let words = wordsByCategory[category] {
                                wordSection(category, words: words)
                            }
                        }
                        if filteredWords.isEmpty {
                            ContentUnavailableView.search(text: query)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .searchable(text: $query, prompt: "Search words")
            .fullScreenCover(isPresented: $isWordPracticePresented) {
                WordPracticeView()
            }
            .fullScreenCover(isPresented: $isEndlessPresented) {
                EndlessPracticeView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Your learning path")
                .scaledFont(30, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                .foregroundStyle(AppTheme.ink)
            Text("All 33 letters first, then your first Georgian words")
                .foregroundStyle(AppTheme.secondary)
        }
    }

    @ViewBuilder private var practice: some View {
        Text("Practice")
            .font(.title3.bold())
            .foregroundStyle(AppTheme.ink)
            .padding(.top, 6)
        if store.isPathComplete {
            WordPracticeCard { isWordPracticePresented = true }
            EndlessPracticeCard { isEndlessPresented = true }
        } else {
            LockedModeCard(eyebrow: "FIRST WORDS", title: "Build words from letters",
                           subtitle: "Unlocks after all 33 letters",
                           symbol: "textformat.abc", tint: AppTheme.coral)
            LockedModeCard(eyebrow: "ENDLESS MODE", title: "Keep the letters flowing",
                           subtitle: "\(store.learnedLetterIDs.count) of \(GeorgianLetter.all.count) letters learned",
                           symbol: "infinity", tint: AppTheme.violet)
        }
    }

    private var wordsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Words")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
            Text("Read, pronounce and remember \(GeorgianWord.all.count) useful words")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
        }
        .padding(.top, 6)
    }

    private func wordSection(_ category: WordCategory, words: [GeorgianWord]) -> some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text(category.title)
                .font(.caption.bold())
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(AppTheme.secondary)
                .accessibilityAddTraits(.isHeader)

            ForEach(words) { word in
                wordCard(word)
            }
        }
    }

    private func wordCard(_ word: GeorgianWord) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                wordText(word).frame(minWidth: 112, alignment: .leading)
                wordDetails(word)
                Spacer()
                learnedMark(word)
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    wordText(word)
                    wordDetails(word)
                }
                Spacer()
                learnedMark(word)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(word.transliteration), \(Text(word.translation))"))
        .accessibilityValue(store.masteredWordIDs.contains(word.id) ? Text("Learned") : Text(verbatim: ""))
    }

    private func wordText(_ word: GeorgianWord) -> some View {
        Text(verbatim: word.text)
            .scaledFont(27, design: .rounded, relativeTo: .title2)
            .foregroundStyle(AppTheme.violet)
            .fixedSize()
    }

    private func wordDetails(_ word: GeorgianWord) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(word.translation)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(verbatim: word.transliteration)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
        }
    }

    @ViewBuilder private func learnedMark(_ word: GeorgianWord) -> some View {
        if store.masteredWordIDs.contains(word.id) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.mint)
        }
    }
}

struct AlphabetPathSection: View {
    @Environment(LearningStore.self) private var store
    @State private var isCompletedPathExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your alphabet path")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(store.learnedLetterIDs.count)/\(GeorgianLetter.all.count)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondary)
            }

            if store.isPathComplete {
                DisclosureGroup(isExpanded: $isCompletedPathExpanded) {
                    units.padding(.top, 12)
                } label: {
                    Label("All 33 letters learned", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                        .padding(.vertical, 8)
                }
                .tint(AppTheme.violet)
                .padding(18)
                .glassEffect(.regular, in: .rect(cornerRadius: 26))
                .accessibilityIdentifier("completedAlphabetPath")
            } else {
                units
            }
        }
        .onChange(of: store.isPathComplete) { _, _ in
            isCompletedPathExpanded = false
        }
    }

    private var units: some View {
        VStack(spacing: 12) {
            ForEach(LearningUnit.all) { unit in
                unitCard(unit)
            }
        }
    }

    private func unitCard(_ unit: LearningUnit) -> some View {
        let letters = GeorgianLetter.all.filter { $0.unit == unit.id }
        let done = letters.filter { store.learnedLetterIDs.contains($0.id) }.count
        let unlocked = unit.id == 1
            || GeorgianLetter.all
                .filter { $0.unit < unit.id }
                .allSatisfy { store.learnedLetterIDs.contains($0.id) }
        let color = AppTheme.color(named: unit.colorName)

        return Button {
            store.isLessonPresented = true
        } label: {
            GlassCard {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.14))
                            .frame(width: 54, height: 54)
                        Image(systemName: unlocked ? unit.icon : "lock.fill")
                            .font(.title3.bold())
                            .foregroundStyle(color)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("UNIT \(unit.id)")
                            .font(.caption2.bold())
                            .tracking(1)
                            .foregroundStyle(color)
                        Text(unit.title)
                            .font(.headline.bold())
                            .foregroundStyle(AppTheme.ink)
                        Text(unit.subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                        ProgressView(value: Double(done), total: Double(letters.count))
                            .tint(color)
                    }

                    Spacer()
                    Text("\(done)/\(letters.count)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.65)
        .accessibilityElement(children: .combine)
    }
}
