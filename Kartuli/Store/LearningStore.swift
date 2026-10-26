import Foundation
import Observation
import SwiftUI
import WidgetKit

enum AppTab: Hashable {
    case today, learn, alphabet, profile
}

/// Everything about the learner's progress except the activity history, stored
/// as one JSON value. The history lives under its own key so that a single
/// answer never re-serializes years of dates.
struct LearningProgress: Codable, Equatable {
    var learnedLetterIDs: Set<Int> = []
    var xp = 0
    var streak = 0
    var longestStreak = 0
    var dailyProgress = 0
    var dailyProgressDate: Date?
    var endlessBest = 0
    var masteredWordIDs: Set<Int> = []
    var learningStartedAt: Date
}

@Observable
@MainActor
final class LearningStore {
    var selectedTab = AppTab.today
    var isLessonPresented = false
    private(set) var learnedLetterIDs: Set<Int>
    private(set) var xp: Int
    private(set) var streak: Int
    private(set) var longestStreak: Int
    private(set) var dailyProgress: Int
    private(set) var endlessBest: Int
    private(set) var masteredWordIDs: Set<Int>
    private(set) var activityDates: [Date]
    private(set) var currentDay: Date
    private var activityDays: Set<Date>

    /// A streak day is complete once the learner earns this many XP.
    let streakXPThreshold = 30
    let learningStartedAt: Date
    let welcomeMessage: String

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let nowProvider: () -> Date
    @ObservationIgnored private let widgetDefaults: UserDefaults?
    @ObservationIgnored private let reloadWidget: () -> Void
    @ObservationIgnored private let cancelReminder: (Date) -> Void
    @ObservationIgnored private var lastActivity: Date?
    @ObservationIgnored private var progressDate: Date?
    @ObservationIgnored private var indexedTimeZone: TimeZone
    @ObservationIgnored private var persisted: LearningProgress?
    @ObservationIgnored private var persistedDates: [Date]?

    enum Keys {
        static let progress = "learningProgress"
        static let activityDates = "activityDates"
        static let dataVersion = "learningDataVersion"
        static let endlessScoreDataVersion = "endlessScoreDataVersion"

        /// Individual keys used before `LearningProgress`; read once, then removed.
        enum Legacy {
            static let learnedLetterIDs = "learnedLetterIDs"
            static let xp = "xp"
            static let streak = "streak"
            static let longestStreak = "longestStreak"
            static let dailyProgress = "dailyProgress"
            static let dailyProgressDate = "dailyProgressDate"
            static let endlessBest = "endlessBest"
            static let masteredWordIDs = "masteredWordIDs"
            static let learningStartedAt = "learningStartedAt"

            static let all = [learnedLetterIDs, xp, streak, longestStreak, dailyProgress,
                              dailyProgressDate, endlessBest, masteredWordIDs, learningStartedAt]
        }
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
        welcomeMessage = WelcomeMessage.all.randomElement().map { String(localized: $0) }
            ?? String(localized: "Ready for your Georgian moment?")

        let now = nowProvider()
        if defaults.integer(forKey: Keys.dataVersion) < Self.currentDataVersion {
            // Earlier builds shipped with sample progress. Start every existing
            // test installation with clean, real user data once.
            (Keys.Legacy.all + [Keys.progress, Keys.activityDates]).forEach(defaults.removeObject(forKey:))
            defaults.set(Self.currentDataVersion, forKey: Keys.dataVersion)
            defaults.set(now, forKey: Keys.Legacy.learningStartedAt)
        }
        if defaults.integer(forKey: Keys.endlessScoreDataVersion) < 1 {
            // Older builds stored the best combo here. Endless high score now
            // represents the number of correct answers in a session.
            defaults.removeObject(forKey: Keys.Legacy.endlessBest)
            defaults.set(1, forKey: Keys.endlessScoreDataVersion)
        }

        let stored = defaults.data(forKey: Keys.progress)
            .flatMap { try? JSONDecoder().decode(LearningProgress.self, from: $0) }
        let progress = stored ?? Self.legacyProgress(in: defaults, now: now)
        persisted = stored

        learningStartedAt = progress.learningStartedAt
        learnedLetterIDs = progress.learnedLetterIDs
        xp = progress.xp
        streak = progress.streak
        endlessBest = progress.endlessBest
        masteredWordIDs = progress.masteredWordIDs
        let savedActivityDates = defaults.array(forKey: Keys.activityDates) as? [Date] ?? []
        activityDates = savedActivityDates
        persistedDates = savedActivityDates
        activityDays = Set(savedActivityDates.map { calendar.startOfDay(for: $0) })
        lastActivity = savedActivityDates.max()
        // Recover existing records before an expired current streak is reset.
        longestStreak = max(
            progress.longestStreak,
            progress.streak,
            Self.longestRun(in: savedActivityDates, calendar: calendar)
        )

        progressDate = progress.dailyProgressDate
        dailyProgress = progressDate.map { calendar.isDate($0, inSameDayAs: now) } == true
            ? progress.dailyProgress
            : 0

        refreshForCurrentDay(now: now)
        if stored == nil {
            Keys.Legacy.all.forEach(defaults.removeObject(forKey:))
        }
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

    var todayLabel: LocalizedStringResource {
        hasSecuredStreakToday ? "STREAK SECURED" : "\(xpUntilStreak) XP TO STREAK"
    }

    var hasSecuredStreakToday: Bool {
        activityDays.contains(currentDay)
    }

    var xpUntilStreak: Int {
        max(0, streakXPThreshold - dailyProgress)
    }

    var currentWeekActivity: [(date: Date, isActive: Bool)] {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let weekStart = mondayCalendar.dateInterval(of: .weekOfYear, for: currentDay)?.start
            ?? currentDay

        return (0..<7).map { offset in
            let date = mondayCalendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            return (date, activityDays.contains(mondayCalendar.startOfDay(for: date)))
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
        let next = LearningProgress(
            learnedLetterIDs: learnedLetterIDs, xp: xp, streak: streak,
            longestStreak: longestStreak, dailyProgress: dailyProgress,
            dailyProgressDate: progressDate, endlessBest: endlessBest,
            masteredWordIDs: masteredWordIDs, learningStartedAt: learningStartedAt
        )
        // Persist immediately, but skip writes when nothing changed.
        if persisted != next, let data = try? JSONEncoder().encode(next) {
            defaults.set(data, forKey: Keys.progress)
            persisted = next
        }
        if persistedDates != activityDates {
            defaults.set(activityDates, forKey: Keys.activityDates)
            persistedDates = activityDates
        }
        syncStreakToWidget()
    }

    private static func legacyProgress(in defaults: UserDefaults, now: Date) -> LearningProgress {
        LearningProgress(
            learnedLetterIDs: Set(defaults.array(forKey: Keys.Legacy.learnedLetterIDs) as? [Int] ?? []),
            xp: defaults.integer(forKey: Keys.Legacy.xp),
            streak: defaults.integer(forKey: Keys.Legacy.streak),
            longestStreak: defaults.integer(forKey: Keys.Legacy.longestStreak),
            dailyProgress: defaults.integer(forKey: Keys.Legacy.dailyProgress),
            dailyProgressDate: defaults.object(forKey: Keys.Legacy.dailyProgressDate) as? Date,
            endlessBest: defaults.integer(forKey: Keys.Legacy.endlessBest),
            masteredWordIDs: Set(defaults.array(forKey: Keys.Legacy.masteredWordIDs) as? [Int] ?? []),
            learningStartedAt: defaults.object(forKey: Keys.Legacy.learningStartedAt) as? Date ?? now
        )
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
}
