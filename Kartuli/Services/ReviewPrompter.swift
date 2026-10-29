import StoreKit
import SwiftUI

/// Asks for an App Store rating once the learner has finished a few successful
/// sessions, at most once per app version. The system additionally limits how
/// often the prompt appears.
enum ReviewPrompter {
    /// The rating prompt appears from this successful session on.
    static let minimumSuccessfulSessions = 3
    private static let lastPromptedVersionKey = "lastReviewPromptVersion"
    private static let successfulSessionsKey = "successfulSessionCount"

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// Records a successful session and returns whether to ask for a rating now.
    static func recordSuccessfulSession(defaults: UserDefaults = .standard) -> Bool {
        // UI tests must not be interrupted by the system rating sheet.
        guard !ProcessInfo.processInfo.arguments.contains("--qa-suite") else { return false }
        let count = defaults.integer(forKey: successfulSessionsKey) + 1
        defaults.set(count, forKey: successfulSessionsKey)
        return count >= minimumSuccessfulSessions
            && defaults.string(forKey: lastPromptedVersionKey) != appVersion
    }

    static func markPrompted(defaults: UserDefaults = .standard) {
        defaults.set(appVersion, forKey: lastPromptedVersionKey)
    }
}

private struct ReviewRequestModifier: ViewModifier {
    let isEligible: Bool
    @Environment(\.requestReview) private var requestReview

    func body(content: Content) -> some View {
        content.task(id: isEligible) {
            guard isEligible, ReviewPrompter.recordSuccessfulSession() else { return }
            // Let the completion screen land before the rating sheet appears.
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            ReviewPrompter.markPrompted()
            requestReview()
        }
    }
}

extension View {
    /// Counts a successful session whenever `isEligible` becomes true and shows
    /// the App Store rating prompt once enough sessions have been completed.
    func requestsReview(when isEligible: Bool) -> some View {
        modifier(ReviewRequestModifier(isEligible: isEligible))
    }
}
