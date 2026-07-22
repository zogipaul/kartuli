import SwiftUI

@main
struct KartuliApp: App {
    @StateObject private var store = LearningStore()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refreshForCurrentDay()
            }
        }
    }
}
