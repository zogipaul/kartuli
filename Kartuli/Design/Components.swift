import SwiftUI

// MARK: - Dynamic Type

private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let maxSize: CGFloat?
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo style: Font.TextStyle, maxSize: CGFloat?) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.maxSize = maxSize
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: maxSize.map { min(size, $0) } ?? size, weight: weight, design: design))
    }
}

extension View {
    /// A custom-sized system font that still follows Dynamic Type. Display glyphs
    /// pass `maxSize` so they grow with the text setting without leaving the screen.
    func scaledFont(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle = .body,
        maxSize: CGFloat? = nil
    ) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, design: design, relativeTo: style, maxSize: maxSize))
    }
}

// MARK: - Buttons

struct CloseButton: View {
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: .circle)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Mode cards

/// The colorful entry point for a practice mode.
struct ModeCard: View {
    let icon: String
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var trailingIcon = "arrow.right"
    let gradient: LinearGradient
    let shadow: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 62, height: 62)
                    Image(systemName: icon)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrow)
                        .font(.caption2.bold())
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.yellow)
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer(minLength: 4)
                Image(systemName: trailingIcon)
                    .foregroundStyle(AppTheme.onLightSurface)
                    .padding(13)
                    .background(.white, in: Circle())
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(gradient, in: RoundedRectangle(cornerRadius: 27, style: .continuous))
            .shadow(color: shadow.opacity(0.21), radius: 16, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// A practice mode that is not available yet.
struct LockedModeCard: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 62, height: 62)
                Image(systemName: "lock.fill")
                    .font(.title3.bold())
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.caption2.bold())
                    .tracking(1.1)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: symbol)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.secondary.opacity(0.65))
                .accessibilityHidden(true)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 27))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Answer options

enum AnswerState {
    case idle, selected, correct, wrong

    var color: Color {
        switch self {
        case .idle: AppTheme.ink
        case .selected: AppTheme.violet
        case .correct: AppTheme.mint
        case .wrong: AppTheme.coral
        }
    }

    var glass: Glass {
        switch self {
        case .idle: .regular
        case .selected: .regular.tint(AppTheme.violet.opacity(0.14))
        case .correct: .regular.tint(AppTheme.mint.opacity(0.16))
        case .wrong: .regular.tint(AppTheme.coral.opacity(0.12))
        }
    }
}

/// The two-column multiple-choice grid shared by lessons and Endless Mode.
struct AnswerOptionGrid: View {
    let options: [GeorgianLetter]
    var showsSound = false
    let state: (GeorgianLetter) -> AnswerState
    let onSelect: (GeorgianLetter) -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var height: CGFloat = 124

    var body: some View {
        let tileHeight = min(height, showsSound ? 150 : 190) * (showsSound ? 0.74 : 1)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
            ForEach(options) { option in
                let state = state(option)
                Button { onSelect(option) } label: {
                    Text(verbatim: showsSound ? option.sound : option.glyph)
                        .scaledFont(showsSound ? 29 : 56, design: showsSound ? .rounded : .default,
                                    relativeTo: .largeTitle, maxSize: showsSound ? 44 : 84)
                        .foregroundStyle(state.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: tileHeight)
                        .glassEffect(state.glass, in: .rect(cornerRadius: 27))
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(state.color.opacity(state == .idle ? 0 : 0.65), lineWidth: 3)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showsSound ? Text(verbatim: option.sound) : Text(option.spokenName))
                .accessibilityIdentifier(showsSound ? option.sound : option.glyph)
                .accessibilityAddTraits(state == .selected ? .isSelected : [])
            }
        }
    }
}

// MARK: - Metrics

struct StatCard: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(color)
            Text(verbatim: value).font(.title3.bold()).foregroundStyle(AppTheme.ink)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

/// A summary number shown at the end of a practice session.
struct MetricTile: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}
