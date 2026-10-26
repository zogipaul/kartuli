import XCTest
@testable import Kartuli

private final class RecordingDefaults: UserDefaults, @unchecked Sendable {
    var writes: [String] = []

    override func set(_ value: Any?, forKey defaultName: String) {
        writes.append(defaultName)
        super.set(value, forKey: defaultName)
    }
}

@MainActor
final class LearningStoreTests: XCTestCase {
    private var suiteNames: [String] = []
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vienna")!
        return calendar
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func defaults() -> RecordingDefaults {
        let name = "com.example.kartuli.tests.\(UUID().uuidString)"
        suiteNames.append(name)
        let defaults = RecordingDefaults(suiteName: name)!
        defaults.set(2, forKey: "learningDataVersion")
        defaults.set(1, forKey: "endlessScoreDataVersion")
        return defaults
    }

    override func tearDown() {
        for name in suiteNames { UserDefaults.standard.removePersistentDomain(forName: name) }
        suiteNames.removeAll()
        super.tearDown()
    }

    private func store(_ defaults: UserDefaults, now: @escaping () -> Date) -> LearningStore {
        LearningStore(defaults: defaults, calendar: calendar, now: now,
                      widgetDefaults: nil, reloadWidget: {}, cancelReminder: { _ in })
    }

    func testLessonAwardsThirtyXPAndSecuresDayOnlyOnce() {
        let defaults = defaults()
        let now = date("2026-10-24T12:00:00Z")
        let store = store(defaults, now: { now })
        let firstLetters = store.nextLetters
        XCTAssertFalse(store.completeLesson(firstLetters))
        XCTAssertEqual(store.xp, 30)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.dailyProgress, 30)
        XCTAssertEqual(store.learnedLetterIDs, Set([0, 1, 2]))
        XCTAssertEqual(store.nextLetters.map(\.id), [3, 4, 5])
        store.completeLesson(store.nextLetters)
        XCTAssertEqual(store.xp, 60)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.activityDates.count, 1)
        XCTAssertEqual(store.currentWeekActivity.filter(\.isActive).count, 1)
    }

    func testUnlockRequiresAllThirtyThreeLettersAndEmptyLessonAwardsNothing() {
        let now = date("2026-10-24T12:00:00Z")
        let store = store(defaults(), now: { now })
        XCTAssertFalse(store.completeLesson([]))
        XCTAssertEqual(store.xp, 0)
        store.completeEndlessPractice(correct: 15)
        store.completeWord(GeorgianWord.all[0])
        XCTAssertEqual(store.xp, 0)
        for _ in 0..<10 { XCTAssertFalse(store.completeLesson(store.nextLetters)) }
        XCTAssertFalse(store.isEndlessUnlocked)
        XCTAssertTrue(store.completeLesson(store.nextLetters))
        XCTAssertTrue(store.isWordPracticeUnlocked)
        XCTAssertEqual(store.learnedLetterIDs.count, 33)
    }

    func testEndlessThresholdAndPersistenceAcrossRestart() {
        let defaults = defaults()
        defaults.set(Array(0..<33), forKey: "learnedLetterIDs")
        let now = date("2026-10-24T12:00:00Z")
        let store = store(defaults, now: { now })
        store.completeEndlessPractice(correct: 14)
        XCTAssertEqual(store.dailyProgress, 28)
        XCTAssertEqual(store.streak, 0)
        store.completeEndlessPractice(correct: 0)
        XCTAssertEqual(store.xp, 28)
        store.completeEndlessPractice(correct: 1)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.endlessBest, 14)
        let restored = self.store(defaults, now: { now })
        XCTAssertEqual(restored.xp, 30)
        XCTAssertEqual(restored.streak, 1)
        XCTAssertTrue(restored.hasSecuredStreakToday)
        XCTAssertEqual(restored.endlessBest, 14)
    }

    func testConsecutiveDaysAcrossDSTAndMissedDayPreserveRecord() {
        let defaults = defaults()
        var now = date("2026-10-24T12:00:00Z")
        let store = store(defaults, now: { now })
        store.completeLesson(store.nextLetters)
        now = date("2026-10-25T12:00:00Z")
        store.refreshForCurrentDay()
        XCTAssertEqual(store.dailyProgress, 0)
        XCTAssertEqual(store.streak, 1)
        XCTAssertFalse(store.hasSecuredStreakToday)
        store.completeLesson(store.nextLetters)
        XCTAssertEqual(store.streak, 2)
        now = date("2026-10-27T12:00:00Z")
        store.refreshForCurrentDay()
        XCTAssertEqual(store.streak, 0)
        XCTAssertEqual(store.longestStreak, 2)
        store.completeLesson(store.nextLetters)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.longestStreak, 2)
    }

    func testMidnightResetIsPersistedWithoutCompletingAnotherActivity() {
        let defaults = defaults()
        defaults.set(Array(0..<33), forKey: "learnedLetterIDs")
        var now = date("2026-10-24T21:59:00Z")
        let store = store(defaults, now: { now })
        store.completeEndlessPractice(correct: 3)
        XCTAssertEqual(store.dailyProgress, 6)
        now = date("2026-10-24T22:01:00Z")
        store.refreshForCurrentDay()
        XCTAssertEqual(store.dailyProgress, 0)
        XCTAssertEqual(self.store(defaults, now: { now }).dailyProgress, 0)
        store.completeEndlessPractice(correct: 1)
        XCTAssertEqual(store.dailyProgress, 2)
    }

    func testRepeatedRefreshAndWordAnswersAvoidUnchangedWritesAndWidgetReloads() {
        let defaults = defaults()
        let widgetDefaults = self.defaults()
        defaults.set(Array(0..<33), forKey: "learnedLetterIDs")
        let now = date("2026-10-24T12:00:00Z")
        var reloads = 0
        var cancellations = 0
        let store = LearningStore(defaults: defaults, calendar: calendar, now: { now },
                                  widgetDefaults: widgetDefaults, reloadWidget: { reloads += 1 },
                                  cancelReminder: { _ in cancellations += 1 })
        XCTAssertEqual(reloads, 1)
        defaults.writes.removeAll()
        for _ in 0..<10 { store.refreshForCurrentDay() }
        XCTAssertTrue(defaults.writes.isEmpty)
        XCTAssertEqual(reloads, 1)
        for _ in 0..<5 { store.completeWord(GeorgianWord.all[0]) }
        XCTAssertEqual(store.xp, 25)
        XCTAssertEqual(reloads, 1)
        XCTAssertFalse(defaults.writes.contains("activityDates"))
        XCTAssertFalse(defaults.writes.contains("learnedLetterIDs"))
        store.completeWord(GeorgianWord.all[0])
        XCTAssertEqual(reloads, 2)
        XCTAssertEqual(cancellations, 1)
        defaults.writes.removeAll()
        store.completeWord(GeorgianWord.all[0])
        XCTAssertEqual(reloads, 2)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(Set(defaults.writes), [LearningStore.Keys.progress])

        // A timeline generated in another time zone has a different midnight.
        widgetDefaults.set("America/Los_Angeles", forKey: StreakSnapshot.timeZoneKey)
        store.refreshForCurrentDay()
        XCTAssertEqual(reloads, 3)
        XCTAssertEqual(widgetDefaults.string(forKey: StreakSnapshot.timeZoneKey), calendar.timeZone.identifier)
    }

    func testLongestStreakRecoveryDeduplicatesAndSortsHistory() {
        let defaults = defaults()
        defaults.set([date("2026-10-22T12:00:00Z"), date("2026-10-20T12:00:00Z"),
                      date("2026-10-21T12:00:00Z"), date("2026-10-21T13:00:00Z")], forKey: "activityDates")
        let now = date("2026-10-25T12:00:00Z")
        let store = store(defaults, now: { now })
        XCTAssertEqual(store.longestStreak, 3)
        XCTAssertEqual(store.streak, 0)
    }

    func testWidgetExpiryUsesCalendarDaysAcrossBothDSTTransitions() {
        for (last, expiry, hours) in [
            ("2026-10-24T12:00:00Z", "2026-10-25T23:00:00Z", 49.0),
            ("2026-03-28T12:00:00Z", "2026-03-29T22:00:00Z", 47.0)
        ] {
            let last = date(last)
            let snapshot = StreakSnapshot(streak: 7, lastActivity: last)
            let expiration = snapshot.expirationDate(calendar: calendar)!
            XCTAssertEqual(expiration, date(expiry))
            XCTAssertEqual(expiration.timeIntervalSince(calendar.startOfDay(for: last)), hours * 3600)
            XCTAssertEqual(snapshot.value(at: expiration.addingTimeInterval(-1), calendar: calendar), 7)
            XCTAssertEqual(snapshot.value(at: expiration, calendar: calendar), 0)
        }
        XCTAssertEqual(StreakSnapshot(streak: 7, lastActivity: nil).value(at: Date(), calendar: calendar), 0)
    }

    func testEveryQuizHasOneAnswerAndThreeDistinctDistractors() {
        for answer in GeorgianLetter.all {
            for _ in 0..<20 {
                let options = GeorgianLetter.quizOptions(for: answer)
                XCTAssertEqual(options.count, 4)
                XCTAssertEqual(Set(options.map(\.id)).count, 4)
                XCTAssertEqual(options.filter { $0.id == answer.id }.count, 1)
            }
        }
    }

    func testLearningContentHasStableUniqueIDsAndKnownCategories() {
        XCTAssertEqual(GeorgianLetter.all.count, 33)
        XCTAssertEqual(Set(GeorgianLetter.all.map(\.glyph)).count, 33)
        XCTAssertEqual(Set(GeorgianWord.all.map(\.id)).count, GeorgianWord.all.count)
        XCTAssertTrue(GeorgianWord.all.allSatisfy { !$0.text.isEmpty })
    }

    func testWordTransliterationsUseTheLetterRomanization() {
        let sounds = Dictionary(uniqueKeysWithValues: GeorgianLetter.all.map { ($0.glyph, $0.sound) })
        for word in GeorgianWord.all {
            let expected = word.letters.map { sounds[$0] ?? "?" }.joined()
            XCTAssertEqual(word.transliteration, expected, word.text)
        }
    }

    func testLegacyKeysMigrateIntoOneProgressValue() throws {
        let defaults = defaults()
        let started = date("2026-09-01T08:00:00Z")
        let now = date("2026-10-24T12:00:00Z")
        defaults.set([0, 1, 2], forKey: "learnedLetterIDs")
        defaults.set(120, forKey: "xp")
        defaults.set(9, forKey: "longestStreak")
        defaults.set(18, forKey: "endlessBest")
        defaults.set([4, 7], forKey: "masteredWordIDs")
        defaults.set(12, forKey: "dailyProgress")
        defaults.set(calendar.startOfDay(for: now), forKey: "dailyProgressDate")
        defaults.set(started, forKey: "learningStartedAt")

        let store = store(defaults, now: { now })
        XCTAssertEqual(store.learnedLetterIDs, [0, 1, 2])
        XCTAssertEqual(store.xp, 120)
        XCTAssertEqual(store.longestStreak, 9)
        XCTAssertEqual(store.endlessBest, 18)
        XCTAssertEqual(store.masteredWordIDs, [4, 7])
        XCTAssertEqual(store.dailyProgress, 12)
        XCTAssertEqual(store.learningStartedAt, started)
        for key in ["learnedLetterIDs", "xp", "longestStreak", "endlessBest", "masteredWordIDs",
                    "dailyProgress", "dailyProgressDate", "learningStartedAt"] {
            XCTAssertNil(defaults.object(forKey: key), key)
        }
        let data = try XCTUnwrap(defaults.data(forKey: LearningStore.Keys.progress))
        XCTAssertEqual(try JSONDecoder().decode(LearningProgress.self, from: data).xp, 120)

        let restored = self.store(defaults, now: { now })
        XCTAssertEqual(restored.xp, 120)
        XCTAssertEqual(restored.dailyProgress, 12)
        XCTAssertEqual(restored.learningStartedAt, started)
    }

    func testGreetingFollowsTimeOfDay() {
        XCTAssertEqual(DayGreeting(hour: 4), .night)
        XCTAssertEqual(DayGreeting(hour: 5), .morning)
        XCTAssertEqual(DayGreeting(hour: 11), .morning)
        XCTAssertEqual(DayGreeting(hour: 12), .day)
        XCTAssertEqual(DayGreeting(hour: 18), .evening)
        XCTAssertEqual(DayGreeting(hour: 22), .night)
    }

    func testLegacyDarkModeBecomesAppearanceSetting() {
        let dark = defaults()
        dark.set(true, forKey: "isDarkMode")
        AppearanceMode.migrateLegacySetting(in: dark)
        XCTAssertEqual(dark.string(forKey: AppearanceMode.storageKey), "dark")
        XCTAssertNil(dark.object(forKey: "isDarkMode"))

        let light = defaults()
        light.set(false, forKey: "isDarkMode")
        AppearanceMode.migrateLegacySetting(in: light)
        XCTAssertNil(light.string(forKey: AppearanceMode.storageKey))
        XCTAssertNil(light.object(forKey: "isDarkMode"))
    }

    func testIndexedWeekLookupMatchesOriginalAlgorithmAndReportsTiming() {
        let defaults = defaults()
        let now = date("2026-10-25T12:00:00Z")
        let dates = (-3650...0).compactMap { calendar.date(byAdding: .day, value: $0, to: now) }
        defaults.set(dates, forKey: "activityDates")
        let store = store(defaults, now: { now })
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let weekStart = mondayCalendar.dateInterval(of: .weekOfYear, for: now)!.start
        let weekDates = (0..<7).map { mondayCalendar.date(byAdding: .day, value: $0, to: weekStart)! }
        let iterations = 100
        let baselineStart = Date()
        var original: [Bool] = []
        for _ in 0..<iterations {
            original = weekDates.map { day in
                dates.contains { mondayCalendar.isDate($0, inSameDayAs: day) }
            }
        }
        let baseline = Date().timeIntervalSince(baselineStart)
        let indexedStart = Date()
        var indexed: [Bool] = []
        for _ in 0..<iterations {
            indexed = store.currentWeekActivity.map(\.isActive)
        }
        let optimized = Date().timeIntervalSince(indexedStart)
        XCTAssertEqual(indexed, original)
        print("WEEK_LOOKUP_BENCHMARK iterations=\(iterations) history=\(dates.count) original_ms=\(baseline * 1000) indexed_ms=\(optimized * 1000)")
    }

    func testWeekLookupPerformanceWithTenYearsOfHistory() {
        let defaults = defaults()
        let now = date("2026-10-25T12:00:00Z")
        let dates = (0..<3650).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        defaults.set(dates, forKey: "activityDates")
        let store = store(defaults, now: { now })
        measure {
            for _ in 0..<1000 {
                XCTAssertEqual(store.currentWeekActivity.count, 7)
            }
        }
    }
}
