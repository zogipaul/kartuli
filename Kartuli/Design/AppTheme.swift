import SwiftUI

enum AppTheme {
    static let ink = Color(light: UIColor(red: 0.10, green: 0.11, blue: 0.18, alpha: 1),
                           dark: UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1))
    static let secondary = Color(light: UIColor(red: 0.37, green: 0.39, blue: 0.49, alpha: 1),
                                 dark: UIColor(red: 0.68, green: 0.70, blue: 0.78, alpha: 1))
    static let coral = Color(red: 0.94, green: 0.25, blue: 0.30)
    static let violet = Color(light: UIColor(red: 0.49, green: 0.34, blue: 0.96, alpha: 1),
                              dark: UIColor(red: 0.65, green: 0.55, blue: 1.00, alpha: 1))
    static let mint = Color(red: 0.21, green: 0.76, blue: 0.58)
    static let yellow = Color(red: 1.00, green: 0.72, blue: 0.16)
    static let blue = Color(red: 0.23, green: 0.58, blue: 0.97)
    static let canvas = Color(light: UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1),
                              dark: UIColor(red: 0.045, green: 0.05, blue: 0.09, alpha: 1))
    static let subtleBorder = Color(light: .white, dark: UIColor.white.withAlphaComponent(0.20))
    static let onLightSurface = Color(red: 0.10, green: 0.11, blue: 0.18)
    static let coralDeep = Color(red: 0.95, green: 0.44, blue: 0.30)
    static let violetDeep = Color(red: 0.35, green: 0.28, blue: 0.86)

    static let heroGradient = LinearGradient(colors: [violet, violetDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let wordsGradient = LinearGradient(colors: [coral, coralDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let endlessGradient = LinearGradient(colors: [violet, blue], startPoint: .topLeading, endPoint: .bottomTrailing)

    static func color(named: String) -> Color {
        switch named {
        case "violet": violet
        case "yellow": yellow
        case "mint": mint
        case "blue": blue
        default: coral
        }
    }
}

private extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.canvas
            Circle().fill(AppTheme.violet.opacity(0.13)).frame(width: 320).blur(radius: 50).offset(x: 160, y: -330)
            Circle().fill(AppTheme.coral.opacity(0.10)).frame(width: 280).blur(radius: 55).offset(x: -170, y: 280)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(18)
            .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color = AppTheme.coral

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .shadow(color: color.opacity(0.25), radius: 14, y: 7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}
