import SwiftUI

struct LessonView: View {
    // Freeze the presented lesson: awarding XP updates store.nextLetters while
    // this sheet is still showing its completion screen.
    @State private var letters: [GeorgianLetter]
    @State private var optionsByLetterID: [Int: [GeorgianLetter]] = [:]

    init(letters: [GeorgianLetter]) {
        _letters = State(initialValue: letters)
    }
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var finished = false
    @State private var didUnlockEndless = false

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
            Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(AppTheme.secondary).frame(width: 44, height: 44).glassEffect(.regular, in: .circle) }
            .accessibilityLabel("Close lesson")
            ProgressView(value: Double(step + 1), total: Double(totalSteps)).tint(AppTheme.coral)
            Text("\(step + 1)/\(totalSteps)").font(.caption.bold()).foregroundStyle(AppTheme.secondary)
        }
    }

    private var discovery: some View {
        VStack(spacing: 20) {
            Text("MEET A NEW LETTER").font(.caption.bold()).tracking(1.3).foregroundStyle(AppTheme.violet)
            ZStack {
                Circle().fill(AppTheme.violet.opacity(0.11)).frame(width: 250, height: 250)
                Circle().stroke(AppTheme.subtleBorder.opacity(0.8), lineWidth: 2).frame(width: 218, height: 218)
                Text(activeLetter.glyph).font(.system(size: 140, weight: .bold)).foregroundStyle(AppTheme.violet)
            }
            VStack(spacing: 6) {
                Text(activeLetter.name.capitalized).font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.ink)
                Text("It sounds like “\(activeLetter.sound)”").font(.title3).foregroundStyle(AppTheme.secondary)
            }
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activeLetter.example).font(.title2.bold()).foregroundStyle(AppTheme.ink)
                            Text(activeLetter.translation.capitalized).foregroundStyle(AppTheme.secondary)
                        }
                        Spacer()
                        Image(systemName: "character.book.closed.fill").foregroundStyle(AppTheme.coral).font(.title2)
                    }
                }
        }
        .padding(.top, 15)
    }

    private var quiz: some View {
        let options = quizOptions
        return VStack(alignment: .leading, spacing: 18) {
            Text("Which letter sounds like “\(activeLetter.sound)”?")
                .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.ink)
            Text("Choose the correct Georgian letter").foregroundStyle(AppTheme.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(options) { option in
                    Button {
                        guard !showFeedback else { return }
                        selectedAnswer = option.id
                    } label: {
                        Text(option.glyph).font(.system(size: 58, weight: .bold))
                            .foregroundStyle(answerColor(option))
                            .frame(maxWidth: .infinity).frame(height: 126)
                            .glassEffect(answerGlass(option), in: .rect(cornerRadius: 28))
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(answerColor(option).opacity(selectedAnswer == option.id || showFeedback ? 0.7 : 0), lineWidth: 3))
                            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 126)
                    .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .buttonStyle(.plain)
                }
            }
            if showFeedback {
                Label(selectedAnswer == activeLetter.id ? "Brilliant! That’s \(activeLetter.name)." : "Almost! This is \(activeLetter.name).",
                      systemImage: selectedAnswer == activeLetter.id ? "checkmark.circle.fill" : "heart.fill")
                    .font(.headline).foregroundStyle(selectedAnswer == activeLetter.id ? AppTheme.mint : AppTheme.coral)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.top, 25)
    }

    private var quizOptions: [GeorgianLetter] {
        optionsByLetterID[activeLetter.id] ?? []
    }

    private func answerColor(_ option: GeorgianLetter) -> Color {
        if showFeedback && option.id == activeLetter.id { return AppTheme.mint }
        if showFeedback && selectedAnswer == option.id { return AppTheme.coral }
        return selectedAnswer == option.id ? AppTheme.violet : AppTheme.ink
    }

    private func answerGlass(_ option: GeorgianLetter) -> Glass {
        if showFeedback && option.id == activeLetter.id { return .regular.tint(AppTheme.mint.opacity(0.16)) }
        return selectedAnswer == option.id ? .regular.tint(AppTheme.violet.opacity(0.14)) : .regular
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
            Text("Lesson complete!").font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.ink)
            Text("You added \(letters.map(\.glyph).joined(separator: "  ")) to your alphabet.").multilineTextAlignment(.center).foregroundStyle(AppTheme.secondary)
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
