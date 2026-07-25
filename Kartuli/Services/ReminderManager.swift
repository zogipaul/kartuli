import Foundation
import UserNotifications

enum ReminderManager {
    private static let legacyNotificationID = "daily-learning-reminder"
    private static let notificationIDPrefix = "daily-learning-reminder-"
    private static let schedulingHorizonInDays = 30

    private static let messages: [(title: String, body: String)] = [
        ("Georgian arc loading…", "One tiny lesson and your streak stays absolutely unbothered."),
        ("Bestie, the alphabet called", "It said your Georgian glow-up is waiting. Just 30 XP."),
        ("Streak check 👀", "Your streak is giving main character. Don’t ghost it now."),
        ("Quick Kartuli side quest", "A few letters, 30 XP, zero dramatic plot twists."),
        ("Your streak has entered the chat", "Secure it before it starts sending “u up?” texts."),
        ("Tiny lesson, huge aura", "Earn 30 XP and keep that Georgian-learning aura immaculate."),
        ("Not to be dramatic…", "But your streak would really love a quick Georgian lesson."),
        ("POV: you open Kartuli", "You learn Georgian, save your streak, and become iconic."),
        ("The streak is streaking", "Keep it that way with one quick lesson. Slay responsibly."),
        ("Low effort, high lore", "30 XP today adds another chapter to your Georgian era."),
        ("Respectfully: lock in", "Your Georgian streak needs just one tiny bit of attention."),
        ("A message from future you", "Thanks for doing that quick Kartuli lesson. Very based."),
        ("Your daily Georgian DLC", "New knowledge is ready. Download it directly into your brain."),
        ("No pressure, but also…", "That streak is looking too cute to lose. Go grab 30 XP."),
        ("Brain gains incoming", "A short Georgian lesson is basically leg day for your neurons."),
        ("Streak maintenance era", "Pop in, earn 30 XP, leave with your crown still on."),
        ("This is your sign", "Yes, this one. Open Kartuli and secure today’s streak."),
        ("Georgian? In this economy?", "Absolutely. A quick lesson costs zero coins and gives big XP."),
        ("The vibes demand Kartuli", "Do one short lesson and restore balance to the timeline."),
        ("Your streak misses you", "It’s been approximately forever. Come earn today’s 30 XP."),
        ("Hot learner summer", "Keep the Georgian streak warm with a quick lesson."),
        ("Plot armor activated", "Complete a lesson now and protect your streak from today’s finale."),
        ("Be so for real rn", "You’re only 30 XP away from another successful streak day."),
        ("Georgian era status: pending", "One quick lesson will change that status to iconic."),
        ("The letters are gossiping", "They heard you might skip today. Prove them wrong."),
        ("Daily slay opportunity", "Learn a little Georgian and keep your streak serving."),
        ("Touch grass later", "First, touch the Georgian alphabet for one quick lesson."),
        ("Streak insurance reminder", "Pay today’s premium: 30 XP and roughly two minutes."),
        ("Your Du— nope, Kartuli owl", "We don’t have an owl. We do have a streak worth saving."),
        ("Tiny task, elite outcome", "A short lesson now keeps your Georgian streak undefeated."),
        ("Consider this a soft launch", "Of today’s Georgian study session. Open Kartuli to go official."),
        ("Streak lore update needed", "Add today’s chapter with 30 XP. The fandom is waiting."),
        ("Georgian brainrot, but useful", "Learn a few letters and keep the productive obsession alive."),
        ("You 🤝 today’s streak", "Make the collab happen with one quick Kartuli lesson."),
        ("The group chat voted", "Unanimous decision: you should earn today’s Georgian XP."),
        ("Certified learning moment", "Open Kartuli, do the thing, collect the streak. Easy."),
        ("Don’t fumble the streak", "You built it. Now secure today with a tiny Georgian lesson."),
        ("A very chill emergency", "Your streak needs 30 XP. No panic, just Kartuli."),
        ("Today’s micro-win awaits", "One lesson. One streak day. Immaculate momentum."),
        ("Georgian glow-up check", "Consistency is the fit. Add 30 XP and wear it proudly."),
        ("The algorithm chose you", "For a highly exclusive two-minute Georgian learning event."),
        ("Breaking news", "Local legend keeps Georgian streak alive with one quick lesson."),
        ("Your streak said bet", "Now match that energy and earn today’s 30 XP."),
        ("Side quest available", "Reward: Georgian knowledge, 30 XP, and unreasonable amounts of aura."),
        ("Keep cooking, chef", "Your Georgian streak is on the menu. Serve one quick lesson."),
        ("We listen, we don’t judge", "Unless you ghost today’s streak. Kidding. Mostly."),
        ("Delulu is the solulu", "Pretend you’re fluent, then make it slightly more true today."),
        ("Momentum looks good on you", "Secure today’s 30 XP and keep the fit complete."),
        ("One lesson, no crumbs", "Finish today’s Georgian goal and leave the streak plate spotless."),
        ("Final boss: 30 XP", "Plot twist: it’s actually a very short Georgian lesson.")
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
                content.title = message.title
                content.body = message.body

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
