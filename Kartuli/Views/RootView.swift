import SwiftUI

struct RootView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            Tab("Today", systemImage: "house.fill", value: AppTab.today) { HomeView() }
            Tab("Learn", systemImage: "map.fill", value: AppTab.learn) { LearnPathView() }
            Tab("Alphabet", systemImage: "character.book.closed.fill", value: AppTab.alphabet) { AlphabetView() }
            Tab("Profile", systemImage: "person.crop.circle.fill", value: AppTab.profile) { ProfileView() }
        }
        .tint(AppTheme.coral)
        .sheet(isPresented: $store.isLessonPresented) {
            LessonView(letters: store.nextLetters)
        }
    }
}
