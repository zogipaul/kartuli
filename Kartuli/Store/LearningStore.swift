import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class LearningStore: ObservableObject {
    static let appGroupID = "group.com.example.kartuli"
    static let sharedStreakKey = "sharedStreak"

    @Published var selectedTab = 0
    @Published private(set) var learnedLetterIDs: Set<Int>
    @Published private(set) var xp: Int
    @Published private(set) var streak: Int
    @Published private(set) var dailyProgress: Int
    @Published private(set) var endlessBest: Int
    @Published private(set) var activityDates: [Date]
    @Published var isLessonPresented = false

    /// A streak day is complete once the learner earns this many XP.
    let streakXPThreshold = 30
    let learningStartedAt: Date

    private let defaults: UserDefaults
    private let calendar: Calendar

    private enum Keys {
        static let dataVersion = "learningDataVersion"
        static let learnedLetterIDs = "learnedLetterIDs"
        static let xp = "xp"
        static let streak = "streak"
        static let dailyProgress = "dailyProgress"
        static let dailyProgressDate = "dailyProgressDate"
        static let endlessBest = "endlessBest"
        static let endlessScoreDataVersion = "endlessScoreDataVersion"
        static let activityDates = "activityDates"
        static let learningStartedAt = "learningStartedAt"
    }

    private static let currentDataVersion = 2

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar

        let now = Date()
        if defaults.integer(forKey: Keys.dataVersion) < Self.currentDataVersion {
            // Earlier builds shipped with sample progress. Start every existing
            // test installation with clean, real user data once.
            Self.removeLegacyProgress(from: defaults)
            defaults.set(Self.currentDataVersion, forKey: Keys.dataVersion)
            defaults.set(now, forKey: Keys.learningStartedAt)
        }
        if defaults.integer(forKey: Keys.endlessScoreDataVersion) < 1 {
            // Older builds stored the best combo here. Endless high score now
            // represents the number of correct answers in a session.
            defaults.removeObject(forKey: Keys.endlessBest)
            defaults.set(1, forKey: Keys.endlessScoreDataVersion)
        }

        learningStartedAt = defaults.object(forKey: Keys.learningStartedAt) as? Date ?? now
        learnedLetterIDs = Set(defaults.array(forKey: Keys.learnedLetterIDs) as? [Int] ?? [])
        xp = defaults.integer(forKey: Keys.xp)
        streak = defaults.integer(forKey: Keys.streak)
        endlessBest = defaults.integer(forKey: Keys.endlessBest)
        activityDates = defaults.array(forKey: Keys.activityDates) as? [Date] ?? []

        let progressDate = defaults.object(forKey: Keys.dailyProgressDate) as? Date
        dailyProgress = progressDate.map(calendar.isDateInToday) == true
            ? defaults.integer(forKey: Keys.dailyProgress)
            : 0

        refreshForCurrentDay(now: now)
        persist()
    }

    var nextLetters: [GeorgianLetter] {
        let remaining = GeorgianLetter.all.filter { !learnedLetterIDs.contains($0.id) }
        return Array((remaining.isEmpty ? GeorgianLetter.all : remaining).prefix(3))
    }

    var isPathComplete: Bool {
        GeorgianLetter.all.allSatisfy { learnedLetterIDs.contains($0.id) }
    }

    var isEndlessUnlocked: Bool {
        isPathComplete
    }

    var todayLabel: String {
        hasSecuredStreakToday ? "STREAK SECURED" : "\(xpUntilStreak) XP TO STREAK"
    }

    var hasSecuredStreakToday: Bool {
        activityDates.contains { calendar.isDate($0, inSameDayAs: Date()) }
    }

    var xpUntilStreak: Int {
        max(0, streakXPThreshold - dailyProgress)
    }

    var currentWeekActivity: [(label: String, isActive: Bool)] {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let weekStart = mondayCalendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? mondayCalendar.startOfDay(for: Date())
        let labels = ["M", "T", "W", "T", "F", "S", "S"]

        return labels.enumerated().map { offset, label in
            let date = mondayCalendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            return (label, activityDates.contains { mondayCalendar.isDate($0, inSameDayAs: date) })
        }
    }

    @discardableResult
    func completeLesson(_ letters: [GeorgianLetter]) -> Bool {
        let wasUnlocked = isEndlessUnlocked
        learnedLetterIDs.formUnion(letters.map(\.id))
        registerActivity(earnedXP: 30)
        return !wasUnlocked && isEndlessUnlocked
    }

    func completeEndlessPractice(correct: Int) {
        guard isEndlessUnlocked else { return }
        endlessBest = max(endlessBest, correct)
        if correct > 0 {
            registerActivity(earnedXP: correct * 2)
        } else {
            persist()
        }
    }

    func refreshForCurrentDay(now: Date = Date()) {
        let previousStreak = streak
        defer {
            if streak != previousStreak {
                defaults.set(streak, forKey: Keys.streak)
            }
            syncStreakToWidget()
        }

        let progressDate = defaults.object(forKey: Keys.dailyProgressDate) as? Date
        if progressDate.map({ calendar.isDate($0, inSameDayAs: now) }) != true {
            dailyProgress = 0
        }

        guard let lastActivity = activityDates.max() else {
            streak = 0
            return
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
        if !calendar.isDate(lastActivity, inSameDayAs: now),
           yesterday.map({ calendar.isDate(lastActivity, inSameDayAs: $0) }) != true {
            streak = 0
        }
    }

    private func registerActivity(earnedXP: Int, now: Date = Date()) {
        refreshForCurrentDay(now: now)

        xp += earnedXP
        dailyProgress = min(streakXPThreshold, dailyProgress + earnedXP)
        defaults.set(now, forKey: Keys.dailyProgressDate)

        let wasAlreadyActiveToday = activityDates.contains { calendar.isDate($0, inSameDayAs: now) }
        if dailyProgress >= streakXPThreshold && !wasAlreadyActiveToday {
            let previousActivity = activityDates.max()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
            if let previousActivity,
               let yesterday,
               calendar.isDate(previousActivity, inSameDayAs: yesterday) {
                streak += 1
            } else {
                streak = 1
            }
            activityDates.append(calendar.startOfDay(for: now))
        }

        persist()
    }

    private func persist() {
        defaults.set(Array(learnedLetterIDs), forKey: Keys.learnedLetterIDs)
        defaults.set(xp, forKey: Keys.xp)
        defaults.set(streak, forKey: Keys.streak)
        defaults.set(dailyProgress, forKey: Keys.dailyProgress)
        defaults.set(endlessBest, forKey: Keys.endlessBest)
        defaults.set(activityDates, forKey: Keys.activityDates)
        defaults.set(learningStartedAt, forKey: Keys.learningStartedAt)
        syncStreakToWidget()
    }

    private func syncStreakToWidget() {
        UserDefaults(suiteName: Self.appGroupID)?.set(streak, forKey: Self.sharedStreakKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "KartuliStreakWidget")
    }

    private static func removeLegacyProgress(from defaults: UserDefaults) {
        [
            Keys.learnedLetterIDs,
            Keys.xp,
            Keys.streak,
            Keys.dailyProgress,
            Keys.dailyProgressDate,
            Keys.endlessBest,
            Keys.activityDates,
            Keys.learningStartedAt
        ].forEach(defaults.removeObject(forKey:))
    }
}
