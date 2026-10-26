import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"
    private static let legacyDarkModeKey = "isDarkMode"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }

    /// Earlier builds stored a light/dark toggle. Keep an explicit dark choice;
    /// the old default (light) becomes "System".
    static func migrateLegacySetting(in defaults: UserDefaults) {
        guard defaults.object(forKey: legacyDarkModeKey) != nil else { return }
        if defaults.string(forKey: storageKey) == nil && defaults.bool(forKey: legacyDarkModeKey) {
            defaults.set(AppearanceMode.dark.rawValue, forKey: storageKey)
        }
        defaults.removeObject(forKey: legacyDarkModeKey)
    }
}
