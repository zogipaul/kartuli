import SwiftUI

struct LearnPathView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Your alphabet path").font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.ink)
                        Text("Small steps. Beautiful letters.").foregroundStyle(AppTheme.secondary)
                        ForEach(LearningUnit.all) { unit in unitCard(unit) }
                    }
                    .padding(20).padding(.bottom, 25)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func unitCard(_ unit: LearningUnit) -> some View {
        let letters = GeorgianLetter.all.filter { $0.unit == unit.id }
        let done = letters.filter { store.learnedLetterIDs.contains($0.id) }.count
        let unlocked = unit.id == 1 || GeorgianLetter.all.filter { $0.unit < unit.id }.allSatisfy { store.learnedLetterIDs.contains($0.id) }
        return GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(AppTheme.color(named: unit.colorName).opacity(unlocked ? 0.16 : 0.07)).frame(width: 68, height: 68)
                    Image(systemName: unlocked ? unit.icon : "lock.fill").font(.title2.bold()).foregroundStyle(unlocked ? AppTheme.color(named: unit.colorName) : .gray)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text("UNIT \(unit.id)").font(.caption2.bold()).foregroundStyle(AppTheme.color(named: unit.colorName))
                    Text(unit.title).font(.headline).foregroundStyle(AppTheme.ink)
                    Text(unit.subtitle).font(.caption).foregroundStyle(AppTheme.secondary)
                    ProgressView(value: Double(done), total: Double(letters.count)).tint(AppTheme.color(named: unit.colorName))
                }
                Spacer()
                Text("\(done)/\(letters.count)").font(.caption.bold()).foregroundStyle(AppTheme.secondary)
            }
            .opacity(unlocked ? 1 : 0.65)
            .contentShape(Rectangle())
            .onTapGesture { if unlocked { store.isLessonPresented = true } }
        }
    }
}

