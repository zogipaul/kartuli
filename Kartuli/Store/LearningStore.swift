import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class LearningStore: ObservableObject {
    @Published var selectedTab = 0
    @Published private(set) var learnedLetterIDs: Set<Int>
    @Published private(set) var xp: Int
    @Published private(set) var streak: Int
    @Published private(set) var longestStreak: Int
    @Published private(set) var dailyProgress: Int
    @Published private(set) var endlessBest: Int
    @Published private(set) var masteredWordIDs: Set<Int>
    @Published private(set) var activityDates: [Date]
    @Published var isLessonPresented = false
    @Published private(set) var currentDay: Date

    /// A streak day is complete once the learner earns this many XP.
    let streakXPThreshold = 30
    let learningStartedAt: Date
    let welcomeMessage: String

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let nowProvider: () -> Date
    private let widgetDefaults: UserDefaults?
    private let reloadWidget: () -> Void
    private let cancelReminder: (Date) -> Void
    private var activityDays: Set<Date>
    private var lastActivity: Date?
    private var progressDate: Date?
    private var indexedTimeZone: TimeZone
    private var persisted: ProgressSnapshot?

    private struct ProgressSnapshot: Equatable {
        let letters: Set<Int>
        let xp: Int
        let streak: Int
        let longestStreak: Int
        let dailyProgress: Int
        let endlessBest: Int
        let words: Set<Int>
        let dates: [Date]
    }

    private enum Keys {
        static let dataVersion = "learningDataVersion"
        static let learnedLetterIDs = "learnedLetterIDs"
        static let xp = "xp"
        static let streak = "streak"
        static let longestStreak = "longestStreak"
        static let dailyProgress = "dailyProgress"
        static let dailyProgressDate = "dailyProgressDate"
        static let endlessBest = "endlessBest"
        static let endlessScoreDataVersion = "endlessScoreDataVersion"
        static let masteredWordIDs = "masteredWordIDs"
        static let activityDates = "activityDates"
        static let learningStartedAt = "learningStartedAt"
    }

    private static let currentDataVersion = 2

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init,
        widgetDefaults: UserDefaults? = UserDefaults(suiteName: StreakSnapshot.appGroupID),
        reloadWidget: @escaping () -> Void = {
            WidgetCenter.shared.reloadTimelines(ofKind: "KartuliStreakWidget")
        },
        cancelReminder: @escaping (Date) -> Void = { ReminderManager.cancelTodayReminder(now: $0) }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.nowProvider = now
        self.widgetDefaults = widgetDefaults
        self.reloadWidget = reloadWidget
        self.cancelReminder = cancelReminder
        indexedTimeZone = calendar.timeZone
        currentDay = calendar.startOfDay(for: now())
        welcomeMessage = WelcomeMessage.all.randomElement()
            ?? "Ready for your Georgian moment?"

        let now = nowProvider()
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
        let savedStreak = defaults.integer(forKey: Keys.streak)
        streak = savedStreak
        endlessBest = defaults.integer(forKey: Keys.endlessBest)
        masteredWordIDs = Set(defaults.array(forKey: Keys.masteredWordIDs) as? [Int] ?? [])
        let savedActivityDates = defaults.array(forKey: Keys.activityDates) as? [Date] ?? []
        activityDates = savedActivityDates
        activityDays = Set(savedActivityDates.map { calendar.startOfDay(for: $0) })
        lastActivity = savedActivityDates.max()
        // Recover existing records before an expired current streak is reset.
        longestStreak = max(
            defaults.integer(forKey: Keys.longestStreak),
            savedStreak,
            Self.longestRun(in: savedActivityDates, calendar: calendar)
        )

        progressDate = defaults.object(forKey: Keys.dailyProgressDate) as? Date
        dailyProgress = progressDate.map { calendar.isDate($0, inSameDayAs: now) } == true
            ? defaults.integer(forKey: Keys.dailyProgress)
            : 0

        refreshForCurrentDay(now: now)
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

    var isWordPracticeUnlocked: Bool {
        isPathComplete
    }

    var todayLabel: String {
        hasSecuredStreakToday ? "STREAK SECURED" : "\(xpUntilStreak) XP TO STREAK"
    }

    var hasSecuredStreakToday: Bool {
        activityDays.contains(currentDay)
    }

    var xpUntilStreak: Int {
        max(0, streakXPThreshold - dailyProgress)
    }

    var currentWeekActivity: [(label: String, isActive: Bool)] {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let weekStart = mondayCalendar.dateInterval(of: .weekOfYear, for: currentDay)?.start
            ?? currentDay
        let labels = ["M", "T", "W", "T", "F", "S", "S"]

        return labels.enumerated().map { offset, label in
            let date = mondayCalendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            return (label, activityDays.contains(mondayCalendar.startOfDay(for: date)))
        }
    }

    @discardableResult
    func completeLesson(_ letters: [GeorgianLetter]) -> Bool {
        guard !letters.isEmpty else { return false }
        let wasUnlocked = isEndlessUnlocked
        learnedLetterIDs.formUnion(letters.map(\.id))
        registerActivity(earnedXP: 30)
        return !wasUnlocked && isEndlessUnlocked
    }

    func completeEndlessPractice(correct: Int) {
        guard isEndlessUnlocked else { return }
        if correct > endlessBest { endlessBest = correct }
        if correct > 0 {
            registerActivity(earnedXP: correct * 2)
        } else {
            persist()
        }
    }

    func completeWord(_ word: GeorgianWord) {
        guard isWordPracticeUnlocked else { return }
        masteredWordIDs.insert(word.id)
        registerActivity(earnedXP: 5)
    }

    func refreshForCurrentDay(now: Date? = nil) {
        let now = now ?? nowProvider()
        let day = calendar.startOfDay(for: now)
        if indexedTimeZone != calendar.timeZone {
            activityDays = Set(activityDates.map { calendar.startOfDay(for: $0) })
            indexedTimeZone = calendar.timeZone
        }
        if currentDay != day { currentDay = day }
        if progressDate.map({ calendar.isDate($0, inSameDayAs: now) }) != true {
            if dailyProgress != 0 { dailyProgress = 0 }
            progressDate = day
            defaults.set(day, forKey: Keys.dailyProgressDate)
        }
        let validStreak = StreakSnapshot(streak: streak, lastActivity: lastActivity)
            .value(at: now, calendar: calendar)
        if streak != validStreak { streak = validStreak }
        persist()
    }

    private func registerActivity(earnedXP: Int) {
        let now = nowProvider()
        refreshForCurrentDay(now: now)

        xp += earnedXP
        let progress = min(streakXPThreshold, dailyProgress + earnedXP)
        if dailyProgress != progress { dailyProgress = progress }

        let wasAlreadyActiveToday = activityDays.contains(currentDay)
        if dailyProgress >= streakXPThreshold && !wasAlreadyActiveToday {
            let previousActivity = lastActivity
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
            if let previousActivity,
               let yesterday,
               calendar.isDate(previousActivity, inSameDayAs: yesterday) {
                streak += 1
            } else {
                streak = 1
            }
            longestStreak = max(longestStreak, streak)
            activityDates.append(currentDay)
            activityDays.insert(currentDay)
            lastActivity = currentDay
            cancelReminder(now)
        }

        persist()
    }

    private func persist() {
        let next = ProgressSnapshot(letters: learnedLetterIDs, xp: xp, streak: streak,
                                    longestStreak: longestStreak, dailyProgress: dailyProgress,
                                    endlessBest: endlessBest, words: masteredWordIDs, dates: activityDates)
        // Persist immediately, but only write fields that actually changed. In
        // particular, a word answer must not serialize the entire activity history.
        if persisted?.letters != next.letters { defaults.set(Array(next.letters), forKey: Keys.learnedLetterIDs) }
        if persisted?.xp != next.xp { defaults.set(next.xp, forKey: Keys.xp) }
        if persisted?.streak != next.streak { defaults.set(next.streak, forKey: Keys.streak) }
        if persisted?.longestStreak != next.longestStreak { defaults.set(next.longestStreak, forKey: Keys.longestStreak) }
        if persisted?.dailyProgress != next.dailyProgress { defaults.set(next.dailyProgress, forKey: Keys.dailyProgress) }
        if persisted?.endlessBest != next.endlessBest { defaults.set(next.endlessBest, forKey: Keys.endlessBest) }
        if persisted?.words != next.words { defaults.set(Array(next.words), forKey: Keys.masteredWordIDs) }
        if persisted?.dates != next.dates { defaults.set(next.dates, forKey: Keys.activityDates) }
        if persisted == nil { defaults.set(learningStartedAt, forKey: Keys.learningStartedAt) }
        persisted = next
        syncStreakToWidget()
    }

    private static func longestRun(in dates: [Date], calendar: Calendar) -> Int {
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        var longest = 0
        var current = 0
        var previous: Date?

        for day in days {
            if let previous,
               calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = day
        }
        return longest
    }

    private func syncStreakToWidget() {
        guard let widgetDefaults else { return }
        let savedStreak = widgetDefaults.object(forKey: StreakSnapshot.streakKey) as? Int
        let savedDate = widgetDefaults.object(forKey: StreakSnapshot.lastActivityKey) as? Date
        let timeZone = calendar.timeZone.identifier
        let savedTimeZone = widgetDefaults.string(forKey: StreakSnapshot.timeZoneKey)
        guard savedStreak != streak || savedDate != lastActivity || savedTimeZone != timeZone else { return }
        widgetDefaults.set(timeZone, forKey: StreakSnapshot.timeZoneKey)
        widgetDefaults.set(streak, forKey: StreakSnapshot.streakKey)
        widgetDefaults.set(lastActivity, forKey: StreakSnapshot.lastActivityKey)
        reloadWidget()
    }

    private static func removeLegacyProgress(from defaults: UserDefaults) {
        [
            Keys.learnedLetterIDs,
            Keys.xp,
            Keys.streak,
            Keys.longestStreak,
            Keys.dailyProgress,
            Keys.dailyProgressDate,
            Keys.endlessBest,
            Keys.activityDates,
            Keys.learningStartedAt
        ].forEach(defaults.removeObject(forKey:))
    }
}
