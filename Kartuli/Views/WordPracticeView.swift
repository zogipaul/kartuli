import SwiftUI

private struct WordTile: Identifiable, Equatable {
    let id = UUID()
    let letter: String
}

struct WordPracticeView: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    @State private var words: [GeorgianWord] = []
    @State private var wordIndex = 0
    @State private var tiles: [WordTile] = []
    @State private var selectedTiles: [WordTile] = []
    @State private var isChecked = false
    @State private var correct = 0
    @State private var showSummary = false

    private var word: GeorgianWord { words[wordIndex] }
    private var assembledWord: String { selectedTiles.map(\.letter).joined() }
    private var isCorrect: Bool { assembledWord == word.text }
    private var answerColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 6),
            count: min(word.letters.count, 6)
        )
    }

    var body: some View {
        ZStack {
            AppBackground()
            if words.isEmpty {
                ProgressView().tint(AppTheme.violet)
            } else if showSummary {
                summary
            } else {
                practice
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            guard words.isEmpty else { return }
            startSession()
        }
    }

    private var practice: some View {
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                Button { showSummary = true } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(AppTheme.secondary)
                        .frame(width: 42, height: 42)
                        .glassEffect(.regular, in: .circle)
                }
                ProgressView(value: Double(wordIndex + 1), total: Double(words.count))
                    .tint(AppTheme.coral)
                Text("\(wordIndex + 1)/\(words.count)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondary)
            }

            VStack(spacing: 7) {
                Text("BUILD YOUR FIRST WORDS")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.violet)
                Text(word.translation.capitalized)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("Tap the letters in the right order")
                    .foregroundStyle(AppTheme.secondary)
            }
            .padding(.top, 8)

            LazyVGrid(columns: answerColumns, spacing: 6) {
                ForEach(word.letters.indices, id: \.self) { index in
                    Text(index < selectedTiles.count ? selectedTiles[index].letter : "•")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(index < selectedTiles.count ? AppTheme.violet : AppTheme.secondary.opacity(0.42))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .glassEffect(.regular.tint(AppTheme.violet.opacity(0.08)), in: .rect(cornerRadius: 16))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 54), spacing: 9)], spacing: 9) {
                ForEach(tiles) { tile in
                    Button {
                        guard !isChecked, !selectedTiles.contains(tile) else { return }
                        selectedTiles.append(tile)
                    } label: {
                        Text(tile.letter)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(selectedTiles.contains(tile) ? AppTheme.secondary.opacity(0.28) : AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .glassEffect(.regular, in: .rect(cornerRadius: 21))
                            .contentShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .contentShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .buttonStyle(.plain)
                    .disabled(selectedTiles.contains(tile))
                }
            }

            HStack(spacing: 18) {
                Button {
                    guard !isChecked else { return }
                    _ = selectedTiles.popLast()
                } label: {
                    Label("Undo", systemImage: "delete.left")
                }
                .disabled(selectedTiles.isEmpty || isChecked)

                Button("Clear") {
                    guard !isChecked else { return }
                    selectedTiles.removeAll()
                }
                .disabled(selectedTiles.isEmpty || isChecked)
            }
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.secondary)

            if isChecked {
                HStack(spacing: 12) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(isCorrect ? AppTheme.mint : AppTheme.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isCorrect ? "Perfect — you built it!" : "Almost — remember this shape")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text("\(word.text) · \(word.transliteration) · \(word.translation)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .glassEffect(.regular.tint((isCorrect ? AppTheme.mint : AppTheme.yellow).opacity(0.10)), in: .rect(cornerRadius: 22))
            }

            Spacer(minLength: 0)
            Button(isChecked ? (wordIndex + 1 == words.count ? "See results" : "Next word") : "Check word") {
                handleAction()
            }
            .buttonStyle(PrimaryButtonStyle(color: canCheck ? AppTheme.coral : .gray))
            .disabled(!canCheck)
        }
        .padding(22)
    }

    private var canCheck: Bool {
        isChecked || selectedTiles.count == word.letters.count
    }

    private func handleAction() {
        if !isChecked {
            if isCorrect {
                correct += 1
                store.completeWord(word)
            }
            withAnimation(.spring(response: 0.35)) { isChecked = true }
        } else if wordIndex + 1 < words.count {
            wordIndex += 1
            prepareTiles()
            selectedTiles.removeAll()
            isChecked = false
        } else {
            withAnimation(.spring(response: 0.35)) { showSummary = true }
        }
    }

    private var summary: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.coral.opacity(0.12)).frame(width: 164, height: 164)
                Image(systemName: "textformat.abc")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(AppTheme.coral)
            }
            VStack(spacing: 7) {
                Text(wordIndex == 0 && correct == 0 ? "Words are waiting" : "First words unlocked")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("You can now move from recognizing letters to reading real Georgian.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondary)
            }
            HStack(spacing: 11) {
                metric("\(correct)/\(words.count)", "this round", AppTheme.mint)
                metric("\(store.masteredWordIDs.count)/\(GeorgianWord.all.count)", "words learned", AppTheme.violet)
            }
            Spacer()
            VStack(spacing: 12) {
                Button("Practice more words") {
                    startSession()
                    withAnimation { showSummary = false }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppTheme.coral))
                Button("Finish for now") { dismiss() }
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(24)
    }

    private func metric(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private func startSession() {
        let unmastered = GeorgianWord.all.filter { !store.masteredWordIDs.contains($0.id) }
        let pool = (unmastered.isEmpty ? GeorgianWord.all : unmastered).shuffled()
        words = Array(pool.prefix(5))
        wordIndex = 0
        selectedTiles.removeAll()
        isChecked = false
        correct = 0
        prepareTiles()
    }

    private func prepareTiles() {
        guard !words.isEmpty else { return }
        tiles = words[wordIndex].letters.map { WordTile(letter: $0) }.shuffled()
    }
}
