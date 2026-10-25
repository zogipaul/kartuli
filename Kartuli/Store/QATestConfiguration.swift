#if DEBUG
import Foundation

/// UI tests use a separate preferences domain, never the learner's saved data.
enum QATestConfiguration {
    static var defaults: UserDefaults? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--qa-suite"),
              arguments.indices.contains(index + 1) else { return nil }
        let suite = arguments[index + 1]
        guard suite.hasPrefix("com.example.kartuli.qa.") else { return nil }
        let defaults = UserDefaults(suiteName: suite)!
        if arguments.contains("--qa-reset") { defaults.removePersistentDomain(forName: suite) }
        defaults.set(2, forKey: "learningDataVersion")
        defaults.set(1, forKey: "endlessScoreDataVersion")
        if arguments.contains("--qa-unlocked") {
            defaults.set(Array(0..<33), forKey: "learnedLetterIDs")
        }
        return defaults
    }
}
#endif
