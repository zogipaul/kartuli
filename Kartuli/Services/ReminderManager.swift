import Foundation
import UserNotifications

enum ReminderManager {
    private static let legacyNotificationID = "daily-learning-reminder"
    private static let notificationIDPrefix = "daily-learning-reminder-"
    private static let schedulingHorizonInDays = 30

    private static let messages: [(title: LocalizedStringResource, body: LocalizedStringResource)] = [
        ("Time for a little Georgian", "One short lesson keeps your streak going."),
        ("Your streak is waiting", "Earn 30 XP today to keep it alive."),
        ("Three letters, a few minutes", "Today’s lesson is ready when you are."),
        ("Keep the momentum", "A quick session now makes tomorrow easier."),
        ("ქართული is calling", "Open Kartuli and secure today’s streak."),
        ("A small step for today", "Learn a few letters and collect your 30 XP."),
        ("Ready for a quick practice?", "Five minutes of Georgian is all it takes."),
        ("Don’t lose your streak", "There’s still time to earn today’s 30 XP."),
        ("New letters are waiting", "Meet them in today’s short lesson."),
        ("Practice makes it stick", "A quick review helps the letters feel familiar."),
        ("Your Georgian moment", "Take a short break and learn something new."),
        ("Almost a habit", "Come back today and keep your learning streak growing."),
        ("A few minutes, real progress", "Today’s Georgian goal is within reach."),
        ("Keep your streak alive", "One lesson or 15 correct answers is enough."),
        ("Letters, words, progress", "Pick up where you left off in Kartuli."),
        ("Good time to practice", "A short Georgian session fits into almost any day."),
        ("Today counts", "Secure your streak with a quick lesson."),
        ("Your next word is close", "Keep learning and read more Georgian every day."),
        ("Steady wins", "Small daily lessons add up faster than you think."),
        ("Still on today’s list", "Finish your Georgian goal before the day ends.")
    ]

    static func setReminder(
        enabled: Bool,
        minutesAfterMidnight: Int,
        hasSecuredStreakToday: Bool
    ) async -> Bool {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            await removeScheduledReminders(from: center)
            return false
        }

        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .badge])
                guard granted else { return false }
            } else if settings.authorizationStatus == .denied {
                return false
            }

            await removeScheduledReminders(from: center)

            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let reminderHour = max(0, min(23, minutesAfterMidnight / 60))
            let reminderMinute = max(0, min(59, minutesAfterMidnight % 60))

            for dayOffset in 0..<schedulingHorizonInDays {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                      let reminderDate = calendar.date(
                        bySettingHour: reminderHour,
                        minute: reminderMinute,
                        second: 0,
                        of: day
                      ),
                      reminderDate > now
                else {
                    continue
                }

                if dayOffset == 0 && hasSecuredStreakToday {
                    continue
                }

                let message = messages.randomElement() ?? messages[0]
                let content = UNMutableNotificationContent()
                content.title = String(localized: message.title)
                content.body = String(localized: message.body)

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: reminderDate
                    ),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: notificationID(for: reminderDate, calendar: calendar),
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
            return true
        } catch {
            return false
        }
    }

    static func cancelTodayReminder(now: Date = Date()) {
        let identifier = notificationID(for: now, calendar: .current)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func removeScheduledReminders(
        from center: UNUserNotificationCenter
    ) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0 == legacyNotificationID || $0.hasPrefix(notificationIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func notificationID(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(notificationIDPrefix)\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
