import Foundation
import UserNotifications

enum ReminderManager {
    static let notificationID = "daily-learning-reminder"

    static func setReminder(enabled: Bool, minutesAfterMidnight: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [notificationID])
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

            let content = UNMutableNotificationContent()
            content.title = "Your Georgian moment"
            content.body = "Keep your streak alive with a short Kartuli lesson."

            var components = DateComponents()
            components.hour = minutesAfterMidnight / 60
            components.minute = minutesAfterMidnight % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: notificationID,
                content: content,
                trigger: trigger
            )

            center.removePendingNotificationRequests(withIdentifiers: [notificationID])
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
