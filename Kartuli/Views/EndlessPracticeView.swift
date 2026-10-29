import SwiftUI

private enum EndlessQuestionKind: CaseIterable {
    case soundToGlyph
    case glyphToSound
    case nameToGlyph

    var instruction: LocalizedStringResource {
        switch self {
        case .soundToGlyph: "Choose the matching letter"
        case .glyphToSound: "Choose the matching sound"
        case .nameToGlyph: "Choose the letter with this name"
        }
    }
}

private struct EndlessQuestion {
    let answer: GeorgianLetter
    let options: [GeorgianLetter]
    let kind: EndlessQuestionKind

    var prompt: LocalizedStringResource {
        switch kind {
        case .soundToGlyph: "Which letter sounds like “\(answer.sound)”?"
        case .glyphToSound: "What sound does this letter make?"
        case .nameToGlyph: "Find “\(answer.name.capitalized)”"
        }
    }

    static func make(avoiding previousID: Int? = nil) -> EndlessQuestion {
        let available = GeorgianLetter.all.filter { $0.id != previousID }
        let answer = available.randomElement() ?? GeorgianLetter.all[0]
        return EndlessQuestion(answer: answer, options: GeorgianLetter.quizOptions(for: answer), kind: EndlessQuestionKind.allCases.randomElement() ?? .soundToGlyph)
    }
}

struct EndlessPracticeView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var question = EndlessQuestion.make()
    @State private var selectedID: Int?
    @State private var isChecked = false
    @State private var rounds = 0
    @State private var correct = 0
    @State private var combo = 0
    @State private var bestCombo = 0
    @State private var showSummary = false
    @State private var didSave = false

    private var accuracy: Int {
        rounds == 0 ? 100 : Int((Double(correct) / Double(rounds) * 100).rounded())
    }

    var body: some View {
        ZStack {
            AppBackground()
            if showSummary { summary }
            else { practice }
        }
        .requestsReview(when: showSummary && correct > 0)
        .interactiveDismissDisabled()
    }

    private var practice: some View {
        ScrollView {
          VStack(spacing: 22) {
            header
            VStack(spacing: 8) {
                Text(question.kind.instruction)
                    .font(.caption.bold()).textCase(.uppercase).tracking(1.2).foregroundStyle(AppTheme.violet)
                Text(question.prompt)
                    .scaledFont(28, weight: .heavy, design: .rounded, relativeTo: .title)
                    .multilineTextAlignment(.center).foregroundStyle(AppTheme.ink)
            }
            .padding(.top, 14)

            if question.kind == .glyphToSound {
                Text(verbatim: question.answer.glyph)
                    .scaledFont(112, relativeTo: .largeTitle, maxSize: 160)
                    .foregroundStyle(AppTheme.violet)
                    .padding(.horizontal, 48).padding(.vertical, 18)
                    .glassEffect(.regular.tint(AppTheme.violet.opacity(0.12)), in: .rect(cornerRadius: 38))
                    .accessibilityLabel(Text(question.answer.spokenName))
            }

            options
            feedback
          }.padding(22)
        }
        .id(question.answer.id)
        .safeAreaInset(edge: .bottom) {
            Button(actionButtonTitle, action: handleAction)
                .buttonStyle(PrimaryButtonStyle(color: selectedID == nil ? .gray : AppTheme.coral))
                .disabled(selectedID == nil)
                .padding(22).background(AppTheme.canvas)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CloseButton(accessibilityLabel: "End endless practice") { showSummary = true }
                VStack(alignment: .leading, spacing: 1) {
                    Text("ENDLESS MODE").font(.caption2.bold()).tracking(1).foregroundStyle(AppTheme.violet)
                    Text("Round \(rounds + (isChecked ? 0 : 1))").font(.headline).foregroundStyle(AppTheme.ink)
                }
                Spacer(minLength: 0)
                if !dynamicTypeSize.isAccessibilitySize { sessionMetrics }
            }
            if dynamicTypeSize.isAccessibilitySize { sessionMetrics }
        }
    }

    private var sessionMetrics: some View {
        HStack(spacing: 12) {
            Label { Text(verbatim: "\(combo)") } icon: { Image(systemName: "bolt.fill") }
                .font(.headline.bold()).foregroundStyle(combo > 1 ? AppTheme.yellow : AppTheme.secondary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
                .accessibilityLabel("Combo: \(combo)")
            Text(verbatim: "\(accuracy)%").font(.headline.bold()).foregroundStyle(AppTheme.mint)
                .fixedSize()
                .accessibilityLabel("Accuracy: \(accuracy) percent")
        }
    }

    private var options: some View {
        AnswerOptionGrid(options: question.options, showsSound: question.kind == .glyphToSound, state: optionState) { option in
            guard !isChecked else { return }
            selectedID = option.id
        }
    }

    @ViewBuilder private var feedback: some View {
        if isChecked {
            let success = selectedID == question.answer.id
            HStack(spacing: 12) {
                Image(systemName: success ? "checkmark.circle.fill" : "arrow.turn.down.right")
                    .font(.title2).foregroundStyle(success ? AppTheme.mint : AppTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(success ? comboMessage : "Good try — keep it moving!").font(.headline).foregroundStyle(AppTheme.ink)
                    Text("\(question.answer.glyph) is \(question.answer.name), sounding like “\(question.answer.sound)”.")
                        .accessibilityLabel(Text("This is \(question.answer.name), sounding like “\(question.answer.sound)”."))
                        .font(.caption).foregroundStyle(AppTheme.secondary)
                }
                Spacer()
            }
            .padding(16)
            .glassEffect(.regular.tint((success ? AppTheme.mint : AppTheme.coral).opacity(0.1)), in: .rect(cornerRadius: 22))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var comboMessage: LocalizedStringResource {
        switch combo {
        case 5...: "Unstoppable! \(combo) in a row"
        case 3...: "Great combo — \(combo) in a row"
        default: "Nice one!"
        }
    }

    private var actionButtonTitle: LocalizedStringKey {
        isChecked ? "Next letter" : "Check answer"
    }

    private func optionState(_ option: GeorgianLetter) -> AnswerState {
        if isChecked && option.id == question.answer.id { return .correct }
        if isChecked && selectedID == option.id { return .wrong }
        return selectedID == option.id ? .selected : .idle
    }

    private func handleAction() {
        if !isChecked {
            let success = selectedID == question.answer.id
            rounds += 1
            if success {
                correct += 1
                combo += 1
                bestCombo = max(bestCombo, combo)
            } else {
                combo = 0
            }
            withAnimation(.spring(response: 0.35)) { isChecked = true }
        } else {
            let previousID = question.answer.id
            withAnimation(.easeInOut(duration: 0.2)) {
                question = EndlessQuestion.make(avoiding: previousID)
                selectedID = nil
                isChecked = false
            }
        }
    }

    private var summary: some View {
        ScrollView {
          VStack(spacing: 24) {
            ZStack {
                Circle().fill(AppTheme.violet.opacity(0.12)).frame(width: 164, height: 164)
                Image(systemName: "infinity").font(.system(size: 72, weight: .bold)).foregroundStyle(AppTheme.violet)
            }
            .accessibilityHidden(true)
            VStack(spacing: 7) {
                Text(rounds == 0 ? "Ready when you are" : "Great practice!")
                    .scaledFont(33, weight: .heavy, design: .rounded, relativeTo: .largeTitle).foregroundStyle(AppTheme.ink)
                Text(rounds == 0 ? "Jump back in and keep the letters flowing." : "Every round makes Georgian feel more familiar.")
                    .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondary)
            }
            HStack(spacing: 11) {
                MetricTile(value: "\(correct)", label: "correct", color: AppTheme.mint)
                MetricTile(value: "\(accuracy)%", label: "accuracy", color: AppTheme.blue)
                MetricTile(value: "\(bestCombo)", label: "best combo", color: AppTheme.yellow)
            }
            Label("+\(correct * 2) XP earned · 30 XP secures your streak", systemImage: "bolt.fill")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.violet)
          }.padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Keep practicing") { withAnimation { showSummary = false } }
                    .buttonStyle(PrimaryButtonStyle(color: AppTheme.violet))
                Button("Finish for now") {
                    saveIfNeeded()
                    dismiss()
                }
                .font(.headline.bold()).foregroundStyle(AppTheme.secondary).padding(.vertical, 8)
            }.padding(24).background(AppTheme.canvas)
        }
    }

    private func saveIfNeeded() {
        guard !didSave else { return }
        store.completeEndlessPractice(correct: correct)
        didSave = true
    }
}
