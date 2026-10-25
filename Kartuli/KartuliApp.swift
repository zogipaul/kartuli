import SwiftUI

@main
struct KartuliApp: App {
    @StateObject private var store = LearningStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LaunchExperienceView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refreshForCurrentDay()
                if UserDefaults.standard.bool(forKey: "reminderEnabled") {
                    let minutes = UserDefaults.standard.integer(forKey: "reminderTimeMinutes")
                    Task {
                        _ = await ReminderManager.setReminder(
                            enabled: true,
                            minutesAfterMidnight: minutes,
                            hasSecuredStreakToday: store.hasSecuredStreakToday
                        )
                    }
                }
            }
        }
    }
}
