import SwiftUI

/// Keeps the real app mounted while the one-shot launch sequence plays over it.
struct LaunchExperienceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppearanceMode.storageKey) private var appearance = AppearanceMode.system
    @State private var isShowingSplash = true
    @State private var isReadyForInteraction = false

    var body: some View {
        ZStack {
            RootView()
                .allowsHitTesting(isReadyForInteraction)
                .accessibilityHidden(!isReadyForInteraction)

            if isShowingSplash {
                SplashScreenView(onFinish: finish)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear(perform: applyInterfaceStyle)
        .onChange(of: isShowingSplash) { applyInterfaceStyle() }
        .onChange(of: appearance) { applyInterfaceStyle() }
        .onChange(of: scenePhase) { _, phase in
            // Returning from an interruption should always reveal the app immediately.
            if phase == .background {
                isShowingSplash = false
                isReadyForInteraction = true
            }
        }
    }

    /// Applied to the window instead of `preferredColorScheme`, which does not
    /// reliably return to the system setting after an explicit scheme was set.
    private func applyInterfaceStyle() {
        let style = isShowingSplash ? .dark : appearance.interfaceStyle
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }

    private func finish() {
        guard isShowingSplash else { return }
        withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.42), completionCriteria: .removed) {
            isShowingSplash = false
        } completion: {
            // The disappearing splash still intercepts touches during its fade.
            // Expose the app to VoiceOver and UI automation only when it is usable.
            isReadyForInteraction = true
        }
    }
}

private struct SplashScreenView: View {
    let onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasEntered = false
    @State private var hasRevealedTitle = false
    @State private var hasSweptLight = false
    @State private var isExiting = false

    private let glyphs = ["ა", "ბ", "გ", "დ", "ე", "ვ"]
    private let cream = Color(red: 1, green: 0.91, blue: 0.77)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width - 40, geometry.size.height * 0.49, 360)

            ZStack {
                Color("SplashBackground")
                    .ignoresSafeArea()

                atmosphere

                VStack(spacing: 16) {
                    emblem(size: size)
                        .scaleEffect(isExiting && !reduceMotion ? 1.12 : 1)

                    VStack(spacing: 12) {
                        Text("Kartuli")
                            .font(.system(size: 49, weight: .bold, design: .rounded))
                            .tracking(-2)
                            .foregroundStyle(cream)

                        Text("A whole new world of letters.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.74))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(hasRevealedTitle || reduceMotion ? 1 : 0)
                    .offset(y: hasRevealedTitle || reduceMotion ? 0 : 16)
                    .blur(radius: hasRevealedTitle || reduceMotion ? 0 : 8)
                }
                .padding(.horizontal, 20)
                .offset(y: -18)
                .opacity(isExiting ? 0 : 1)

                VStack {
                    Spacer()
                    HStack(spacing: 9) {
                        Capsule().fill(AppTheme.coral).frame(width: 18, height: 3)
                        Text("GEORGIAN, ONE LETTER AT A TIME")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.57))
                    }
                    .padding(.bottom, 24)
                    .opacity(hasRevealedTitle || reduceMotion ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: onFinish)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Kartuli")
            .accessibilityHint("Double-tap to skip the introduction")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, onFinish)
            .task(id: reduceMotion) { await play() }
        }
        .dynamicTypeSize(.medium ... .xxxLarge)
    }

    private var atmosphere: some View {
        ZStack {
            Ellipse()
                .fill(AppTheme.violet.opacity(0.40))
                .frame(width: 340, height: 440)
                .blur(radius: 90)
                .offset(x: hasEntered ? 105 : 65, y: -120)

            Circle()
                .fill(AppTheme.coral.opacity(0.24))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: hasEntered ? -140 : -90, y: hasEntered ? 170 : 220)
        }
        .opacity(isExiting ? 0.35 : 1)
        .accessibilityHidden(true)
    }

    private func emblem(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.07), lineWidth: 1)
                .frame(width: size * 0.92, height: size * 0.92)

            Circle()
                .trim(from: 0, to: hasEntered || reduceMotion ? 0.82 : 0)
                .stroke(
                    AngularGradient(colors: [.clear, AppTheme.violet, cream, AppTheme.coral], center: .center),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .rotationEffect(.degrees(hasSweptLight ? 185 : -100))
                .opacity(reduceMotion ? 0.45 : 0.85)

            ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                orbitingGlyph(glyph, index: index, size: size)
            }

            Image("SplashMark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 0.49, height: size * 0.49)
                .clipShape(.rect(cornerRadius: size * 0.14))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.14)
                        .strokeBorder(.white.opacity(0.20), lineWidth: 1)
                }
                .overlay {
                    // A single masked specular pass, with no permanent animation loop.
                    LinearGradient(colors: [.clear, .white.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: size * 0.25, height: size)
                        .rotationEffect(.degrees(24))
                        .offset(x: hasSweptLight ? size * 0.6 : -size * 0.6)
                        .frame(width: size * 0.49, height: size * 0.49)
                        .clipped()
                        .clipShape(.rect(cornerRadius: size * 0.14))
                        .opacity(reduceMotion ? 0 : 1)
                }
                .shadow(color: AppTheme.violet.opacity(0.5), radius: 32, y: 12)
                .rotationEffect(.degrees(hasEntered || reduceMotion ? -6 : -24))
                .rotation3DEffect(.degrees(hasEntered || reduceMotion ? 0 : 35), axis: (x: 0, y: 1, z: 0))
                .scaleEffect(hasEntered || reduceMotion ? 1 : 0.55)
                .opacity(hasEntered || reduceMotion ? 1 : 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func orbitingGlyph(_ glyph: String, index: Int, size: CGFloat) -> some View {
        let angle = Double(index) * .pi / 3 - .pi / 2
        let radius = size * (hasEntered || reduceMotion ? 0.46 : 0.22)
        let colors = [cream, AppTheme.coral, Color.white, AppTheme.mint, cream, AppTheme.violet]

        return Text(glyph)
            .font(.system(size: index.isMultiple(of: 2) ? 27 : 21, weight: .medium))
            .foregroundStyle(colors[index].opacity(0.9))
            .rotationEffect(.degrees(hasEntered || reduceMotion ? 0 : -55))
            .offset(x: cos(angle) * radius, y: sin(angle) * radius)
            .rotationEffect(.degrees(hasSweptLight && !reduceMotion ? 14 : 0))
            .scaleEffect(hasEntered || reduceMotion ? 1 : 0.4)
            .opacity(hasEntered || reduceMotion ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.85, dampingFraction: 0.7).delay(Double(index) * 0.045), value: hasEntered)
    }

    @MainActor
    private func play() async {
        do {
            if reduceMotion {
                // A brief static brand moment; no zoom, orbit, shimmer or blur reveal.
                try await Task.sleep(for: .milliseconds(350))
                onFinish()
                return
            }

            try await Task.sleep(for: .milliseconds(60))
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                hasEntered = true
            }
            try await Task.sleep(for: .milliseconds(360))
            withAnimation(.easeOut(duration: 0.65)) {
                hasRevealedTitle = true
            }
            try await Task.sleep(for: .milliseconds(240))
            withAnimation(.easeInOut(duration: 1.15)) {
                hasSweptLight = true
            }
            try await Task.sleep(for: .milliseconds(1350))
            withAnimation(.easeIn(duration: 0.3)) {
                isExiting = true
            }
            try await Task.sleep(for: .milliseconds(180))
            onFinish()
        } catch {
            // SwiftUI cancels the sequence on skip, backgrounding or removal.
            return
        }
    }
}

#Preview("Launch animation") {
    LaunchExperienceView()
        .environment(LearningStore())
}
