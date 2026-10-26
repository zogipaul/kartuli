import SwiftUI

@main
struct KartuliApp: App {
    @State private var store: LearningStore
    private let preferences: UserDefaults

    init() {
        #if DEBUG
        let testDefaults = QATestConfiguration.defaults
        let defaults = testDefaults ?? UserDefaults.standard
        preferences = defaults
        _store = State(initialValue: LearningStore(
            defaults: defaults,
            widgetDefaults: testDefaults == nil ? UserDefaults(suiteName: StreakSnapshot.appGroupID) : nil,
            cancelReminder: { if testDefaults == nil { ReminderManager.cancelTodayReminder(now: $0) } }
        ))
        #else
        preferences = .standard
        _store = State(initialValue: LearningStore())
        #endif
        AppearanceMode.migrateLegacySetting(in: preferences)
    }
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LaunchExperienceView()
                .environment(store)
                .defaultAppStorage(preferences)
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                    store.refreshForCurrentDay()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    store.refreshForCurrentDay()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refreshForCurrentDay()
                if preferences.bool(forKey: "reminderEnabled") {
                    let minutes = preferences.integer(forKey: "reminderTimeMinutes")
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
