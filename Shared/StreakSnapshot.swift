import Foundation

/// The app and widget use the same calendar-day expiry rule, including DST days.
struct StreakSnapshot: Equatable {
    static let appGroupID = "group.com.example.kartuli"
    static let streakKey = "sharedStreak"
    static let lastActivityKey = "sharedLastActivity"
    static let timeZoneKey = "sharedStreakTimeZone"

    let streak: Int
    let lastActivity: Date?

    func expirationDate(calendar: Calendar) -> Date? {
        guard let lastActivity else { return nil }
        return calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: lastActivity))
    }

    func value(at date: Date, calendar: Calendar) -> Int {
        guard let lastActivity,
              let expiration = expirationDate(calendar: calendar),
              calendar.startOfDay(for: lastActivity) <= date,
              date < expiration else { return 0 }
        return max(0, streak)
    }
}
