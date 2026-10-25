import SwiftUI

struct LearnPathView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var query = ""
    @State private var isWordPracticePresented = false

    private var filteredWords: [GeorgianWord] {
        guard !query.isEmpty else { return GeorgianWord.all }
        return GeorgianWord.all.filter {
            $0.text.contains(query)
                || $0.transliteration.localizedCaseInsensitiveContains(query)
                || $0.translation.localizedCaseInsensitiveContains(query)
                || $0.category.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        let wordsByCategory = Dictionary(grouping: filteredWords, by: \.category)
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header
                        practiceCard
                        ForEach(GeorgianWord.categories, id: \.self) { category in
                            if let words = wordsByCategory[category] {
                                wordSection(category, words: words)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .searchable(text: $query, prompt: "Georgian, pronunciation or meaning")
            .fullScreenCover(isPresented: $isWordPracticePresented) {
                WordPracticeView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Learn Georgian words")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text("Read, pronounce and remember \(GeorgianWord.all.count) useful words")
                .foregroundStyle(AppTheme.secondary)
        }
    }

    private var practiceCard: some View {
        Button {
            if store.isWordPracticeUnlocked {
                isWordPracticePresented = true
            } else {
                store.selectedTab = 2
            }
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 60, height: 60)
                    Image(systemName: store.isWordPracticeUnlocked ? "textformat.abc" : "character.book.closed.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isWordPracticeUnlocked ? "PRACTICE" : "LEARN THE LETTERS FIRST")
                        .font(.caption2.bold())
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.yellow)
                    Text(store.isWordPracticeUnlocked ? "Build words from letters" : "Open your alphabet path")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(store.isWordPracticeUnlocked
                         ? "\(store.masteredWordIDs.count) of \(GeorgianWord.all.count) words learned"
                         : "You can study every word here while you learn all 33 letters")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.right")
                    .foregroundStyle(AppTheme.onLightSurface)
                    .padding(12)
                    .background(.white, in: Circle())
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppTheme.coral, Color(red: 0.95, green: 0.44, blue: 0.30)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 27, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func wordSection(_ category: String, words: [GeorgianWord]) -> some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text(category.uppercased())
                .font(.caption.bold())
                .tracking(1.1)
                .foregroundStyle(AppTheme.secondary)

            ForEach(words) { word in
                wordCard(word)
            }
        }
    }

    private func wordCard(_ word: GeorgianWord) -> some View {
        HStack(spacing: 14) {
            Text(word.text)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.violet)
                .frame(minWidth: 112, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(word.translation.capitalized)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(word.transliteration)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
            }

            Spacer()

            if store.masteredWordIDs.contains(word.id) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.mint)
                    .accessibilityLabel("Learned")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.text), \(word.transliteration), \(word.translation)")
    }
}

struct AlphabetPathSection: View {
    @EnvironmentObject private var store: LearningStore
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

        return GlassCard {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(AppTheme.color(named: unit.colorName).opacity(0.14))
                        .frame(width: 54, height: 54)
                    Image(systemName: unlocked ? unit.icon : "lock.fill")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.color(named: unit.colorName))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("UNIT \(unit.id)")
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(AppTheme.color(named: unit.colorName))
                    Text(unit.title)
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.ink)
                    Text(unit.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    ProgressView(value: Double(done), total: Double(letters.count))
                        .tint(AppTheme.color(named: unit.colorName))
                }

                Spacer()
                Text("\(done)/\(letters.count)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .opacity(unlocked ? 1 : 0.65)
            .onTapGesture {
                if unlocked {
                    store.isLessonPresented = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(unlocked ? .isButton : [])
    }
}
