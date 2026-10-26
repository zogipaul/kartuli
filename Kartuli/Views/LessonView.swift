import SwiftUI

struct LessonView: View {
    // Freeze the presented lesson: awarding XP updates store.nextLetters while
    // this sheet is still showing its completion screen.
    @State private var letters: [GeorgianLetter]
    @State private var optionsByLetterID: [Int: [GeorgianLetter]] = [:]

    init(letters: [GeorgianLetter]) {
        _letters = State(initialValue: letters)
    }
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var finished = false
    @State private var didUnlockEndless = false
    @ScaledMetric(relativeTo: .largeTitle) private var discoveryCircle: CGFloat = 250

    private var activeLetter: GeorgianLetter { letters[min(step / 2, letters.count - 1)] }
    private var isQuiz: Bool { step.isMultiple(of: 2) == false }
    private var totalSteps: Int { letters.count * 2 }

    var body: some View {
        ZStack {
            AppBackground()
            if letters.isEmpty {
                Button("Back to Today") { dismiss() }.buttonStyle(PrimaryButtonStyle()).padding(24)
            } else if finished { completion }
            else {
                ScrollView {
                    VStack(spacing: 24) {
                        topBar
                        if isQuiz { quiz } else { discovery }
                    }
                    .padding(22)
                }
                .id(step)
                .safeAreaInset(edge: .bottom) {
                    actionButton.padding(22).background(AppTheme.canvas)
                }
            }
        }
        .interactiveDismissDisabled(!finished)
        .onAppear {
            for letter in letters where optionsByLetterID[letter.id] == nil {
                optionsByLetterID[letter.id] = GeorgianLetter.quizOptions(for: letter)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            CloseButton(accessibilityLabel: "Close lesson") { dismiss() }
            ProgressView(value: Double(step + 1), total: Double(totalSteps)).tint(AppTheme.coral)
                .accessibilityLabel("Lesson progress")
            Text("\(step + 1)/\(totalSteps)").font(.caption.bold()).foregroundStyle(AppTheme.secondary)
        }
    }

    private var discovery: some View {
        let circle = min(discoveryCircle, 340)
        return VStack(spacing: 20) {
            Text("MEET A NEW LETTER").font(.caption.bold()).tracking(1.3).foregroundStyle(AppTheme.violet)
            ZStack {
                Circle().fill(AppTheme.violet.opacity(0.11)).frame(width: circle, height: circle)
                Circle().stroke(AppTheme.subtleBorder.opacity(0.8), lineWidth: 2).frame(width: circle * 0.87, height: circle * 0.87)
                Text(verbatim: activeLetter.glyph)
                    .font(.system(size: circle * 0.56, weight: .bold))
                    .foregroundStyle(AppTheme.violet)
                    .accessibilityLabel(Text(activeLetter.spokenName))
                    .accessibilityIdentifier(activeLetter.glyph)
            }
            LetterFacts(letter: activeLetter)
        }
        .padding(.top, 15)
    }

    private var quiz: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Which letter sounds like “\(activeLetter.sound)”?")
                .scaledFont(27, design: .rounded, relativeTo: .title)
                .foregroundStyle(AppTheme.ink)
            Text("Choose the correct Georgian letter").foregroundStyle(AppTheme.secondary)
            AnswerOptionGrid(options: optionsByLetterID[activeLetter.id] ?? [], state: answerState) { option in
                guard !showFeedback else { return }
                selectedAnswer = option.id
            }
            if showFeedback {
                let isCorrect = selectedAnswer == activeLetter.id
                Label(isCorrect ? "Brilliant! That’s \(activeLetter.name)." : "Almost! This is \(activeLetter.name).",
                      systemImage: isCorrect ? "checkmark.circle.fill" : "heart.fill")
                    .font(.headline).foregroundStyle(isCorrect ? AppTheme.mint : AppTheme.coral)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.top, 25)
    }

    private func answerState(_ option: GeorgianLetter) -> AnswerState {
        if showFeedback && option.id == activeLetter.id { return .correct }
        if showFeedback && selectedAnswer == option.id { return .wrong }
        return selectedAnswer == option.id ? .selected : .idle
    }

    private var actionButton: some View {
        Button {
            if isQuiz && !showFeedback {
                withAnimation { showFeedback = true }
            } else if step + 1 < totalSteps {
                step += 1; selectedAnswer = nil; showFeedback = false
            } else {
                didUnlockEndless = store.completeLesson(letters)
                withAnimation(.spring) { finished = true }
            }
        } label: {
            Text(isQuiz && !showFeedback ? "Check answer" : (step + 1 == totalSteps ? "Finish lesson" : "Continue"))
        }
        .buttonStyle(PrimaryButtonStyle(color: (isQuiz && selectedAnswer == nil) ? .gray : AppTheme.coral))
        .disabled(isQuiz && selectedAnswer == nil)
    }

    private var completion: some View {
        ScrollView {
          VStack(spacing: 24) {
            ZStack {
                Circle().fill(AppTheme.yellow.opacity(0.22)).frame(width: 180, height: 180)
                Image(systemName: "star.fill").font(.system(size: 82)).foregroundStyle(AppTheme.yellow).symbolEffect(.bounce, value: finished)
            }
            .accessibilityHidden(true)
            Text("Lesson complete!")
                .scaledFont(34, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                .foregroundStyle(AppTheme.ink)
            Text("You added \(letters.map(\.glyph).joined(separator: "  ")) to your alphabet.")
                .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondary)
            if didUnlockEndless {
                Label("Endless Mode + First Words unlocked!", systemImage: "sparkles")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.violet)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.tint(AppTheme.violet.opacity(0.14)), in: .capsule)
                    .transition(.scale.combined(with: .opacity))
            }
            HStack(spacing: 12) {
                StatCard(icon: "bolt.fill", value: "+30", label: "XP earned", color: AppTheme.yellow)
                StatCard(icon: "character.book.closed.fill", value: "\(store.learnedLetterIDs.count)", label: "letters known", color: AppTheme.mint)
            }
          }.padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Back to Today") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                .padding(24).background(AppTheme.canvas)
        }
    }
}
