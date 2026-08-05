import SwiftUI

private enum EndlessQuestionKind: CaseIterable {
    case soundToGlyph
    case glyphToSound
    case nameToGlyph

    var instruction: String {
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

    var prompt: String {
        switch kind {
        case .soundToGlyph: "Which letter sounds like “\(answer.sound)” ?"
        case .glyphToSound: "What sound does this letter make?"
        case .nameToGlyph: "Find “\(answer.name.capitalized)”"
        }
    }

    func optionLabel(_ letter: GeorgianLetter) -> String {
        kind == .glyphToSound ? letter.sound : letter.glyph
    }

    static func make(avoiding previousID: Int? = nil) -> EndlessQuestion {
        let available = GeorgianLetter.all.filter { $0.id != previousID }
        let answer = available.randomElement() ?? GeorgianLetter.all[0]
        let distractors = GeorgianLetter.all.filter { $0.id != answer.id }.shuffled().prefix(3)
        return EndlessQuestion(answer: answer, options: ([answer] + distractors).shuffled(), kind: EndlessQuestionKind.allCases.randomElement() ?? .soundToGlyph)
    }
}

struct EndlessPracticeView: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
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
        .interactiveDismissDisabled()
    }

    private var practice: some View {
        VStack(spacing: 22) {
            header
            VStack(spacing: 8) {
                Text(question.kind.instruction.uppercased())
                    .font(.caption.bold()).tracking(1.2).foregroundStyle(AppTheme.violet)
                Text(question.prompt)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center).foregroundStyle(AppTheme.ink)
            }
            .padding(.top, 14)

            if question.kind == .glyphToSound {
                Text(question.answer.glyph)
                    .font(.system(size: 112, weight: .bold))
                    .foregroundStyle(AppTheme.violet)
                    .frame(width: 210, height: 190)
                    .glassEffect(.regular.tint(AppTheme.violet.opacity(0.12)), in: .rect(cornerRadius: 38))
            }

            options
            feedback
            Spacer(minLength: 4)
            Button(actionButtonTitle, action: handleAction)
                .buttonStyle(PrimaryButtonStyle(color: selectedID == nil ? .gray : AppTheme.coral))
                .disabled(selectedID == nil)
        }
        .padding(22)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { showSummary = true } label: {
                Image(systemName: "xmark").font(.headline).foregroundStyle(AppTheme.secondary)
                    .frame(width: 42, height: 42).glassEffect(.regular, in: .circle)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("ENDLESS MODE").font(.caption2.bold()).tracking(1).foregroundStyle(AppTheme.violet)
                Text("Round \(rounds + 1)").font(.headline).foregroundStyle(AppTheme.ink)
            }
            Spacer()
            Label("\(combo)", systemImage: "bolt.fill")
                .font(.headline.bold()).foregroundStyle(combo > 1 ? AppTheme.yellow : AppTheme.secondary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
            Text("\(accuracy)%").font(.headline.bold()).foregroundStyle(AppTheme.mint)
        }
    }

    private var options: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
            ForEach(question.options) { option in
                Button {
                    guard !isChecked else { return }
                    selectedID = option.id
                } label: {
                    Text(question.optionLabel(option))
                        .font(question.kind == .glyphToSound ? .system(size: 29, weight: .bold, design: .rounded) : .system(size: 55, weight: .bold))
                        .foregroundStyle(optionColor(option))
                        .frame(maxWidth: .infinity).frame(height: question.kind == .glyphToSound ? 92 : 124)
                        .glassEffect(optionGlass(option), in: .rect(cornerRadius: 27))
                        .overlay(RoundedRectangle(cornerRadius: 27).stroke(optionColor(option).opacity(isHighlighted(option) ? 0.65 : 0), lineWidth: 3))
                        .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .frame(height: question.kind == .glyphToSound ? 92 : 124)
                .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                .buttonStyle(.plain)
            }
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
                        .font(.caption).foregroundStyle(AppTheme.secondary)
                }
                Spacer()
            }
            .padding(16)
            .glassEffect(.regular.tint((success ? AppTheme.mint : AppTheme.coral).opacity(0.1)), in: .rect(cornerRadius: 22))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var comboMessage: String {
        switch combo {
        case 5...: "Unstoppable! \(combo) in a row"
        case 3...: "Great combo — \(combo) in a row"
        default: "Nice one!"
        }
    }

    private var actionButtonTitle: String {
        isChecked ? "Next letter" : "Check answer"
    }

    private func isHighlighted(_ option: GeorgianLetter) -> Bool {
        selectedID == option.id || (isChecked && option.id == question.answer.id)
    }

    private func optionColor(_ option: GeorgianLetter) -> Color {
        if isChecked && option.id == question.answer.id { return AppTheme.mint }
        if isChecked && selectedID == option.id { return AppTheme.coral }
        return selectedID == option.id ? AppTheme.violet : AppTheme.ink
    }

    private func optionGlass(_ option: GeorgianLetter) -> Glass {
        if isChecked && option.id == question.answer.id { return .regular.tint(AppTheme.mint.opacity(0.16)) }
        if selectedID == option.id { return .regular.tint(AppTheme.violet.opacity(0.14)) }
        return .regular
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
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.violet.opacity(0.12)).frame(width: 164, height: 164)
                Image(systemName: "infinity").font(.system(size: 72, weight: .bold)).foregroundStyle(AppTheme.violet)
            }
            VStack(spacing: 7) {
                Text(rounds == 0 ? "Ready when you are" : "Great practice!")
                    .font(.system(size: 33, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.ink)
                Text(rounds == 0 ? "Jump back in and keep the letters flowing." : "Every round makes Georgian feel more familiar.")
                    .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondary)
            }
            HStack(spacing: 11) {
                metric("\(correct)", "correct", AppTheme.mint)
                metric("\(accuracy)%", "accuracy", AppTheme.blue)
                metric("\(bestCombo)", "best combo", AppTheme.yellow)
            }
            Label("+\(correct * 2) XP earned · 30 XP secures your streak", systemImage: "bolt.fill")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.violet)
            Spacer()
            VStack(spacing: 12) {
                Button("Keep practicing") { withAnimation { showSummary = false } }
                    .buttonStyle(PrimaryButtonStyle(color: AppTheme.violet))
                Button("Finish for now") {
                    saveIfNeeded()
                    dismiss()
                }
                .font(.headline.bold()).foregroundStyle(AppTheme.secondary).padding(.vertical, 8)
            }
        }
        .padding(24)
    }

    private func metric(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 17)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private func saveIfNeeded() {
        guard !didSave else { return }
        store.completeEndlessPractice(correct: correct)
        didSave = true
    }
}
