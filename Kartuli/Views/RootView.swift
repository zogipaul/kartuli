import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            Tab("Today", systemImage: "house.fill", value: 0) { HomeView() }
            Tab("Learn", systemImage: "text.book.closed.fill", value: 1) { LearnPathView() }
            Tab("Alphabet", systemImage: "character.book.closed.fill", value: 2) { AlphabetView() }
            Tab("Profile", systemImage: "person.crop.circle.fill", value: 3) { ProfileView() }
        }
        .tint(AppTheme.coral)
        .sheet(isPresented: $store.isLessonPresented) {
            LessonView(letters: store.nextLetters)
        }
    }
}
