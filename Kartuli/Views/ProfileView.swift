import SwiftUI

struct ProfileView: View {
    @Environment(LearningStore.self) private var store
    @AppStorage(AppearanceMode.storageKey) private var appearance = AppearanceMode.system
    @AppStorage("profileAvatar") private var selectedAvatarID = ProfileAvatar.khinkali.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTimeMinutes") private var reminderTimeMinutes = 9 * 60
    @State private var isAvatarPickerPresented = false
    @State private var reminderError: String?
    private var selectedAvatar: ProfileAvatar {
        ProfileAvatar(rawValue: selectedAvatarID) ?? .khinkali
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 9) {
                            Button {
                                isAvatarPickerPresented = true
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    ProfileAvatarImage(avatar: selectedAvatar, size: 96)
                                    Image(systemName: "pencil")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(AppTheme.violet, in: Circle())
                                        .overlay { Circle().stroke(.white, lineWidth: 2) }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose profile avatar")
                            Text("Georgian Explorer").font(.title2.bold()).foregroundStyle(AppTheme.ink)
                            Text("Learning since \(store.learningStartedAt.formatted(date: .abbreviated, time: .omitted))").font(.subheadline).foregroundStyle(AppTheme.secondary)
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack { Text("This week").font(.headline); Spacer(); Label("\(store.streak) days", systemImage: "flame.fill").font(.subheadline.bold()).foregroundStyle(AppTheme.coral) }
                                HStack {
                                    ForEach(store.currentWeekActivity, id: \.date) { day in
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle().fill(day.isActive ? AppTheme.mint : Color.gray.opacity(0.12)).frame(width: 34, height: 34)
                                                Image(systemName: day.isActive ? "checkmark" : "minus").font(.caption.bold()).foregroundStyle(day.isActive ? .white : .gray)
                                            }
                                            Text(day.date, format: .dateTime.weekday(.narrow)).font(.caption2.bold()).foregroundStyle(AppTheme.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide)))
                                        .accessibilityValue(day.isActive ? Text("Streak secured") : Text("No activity"))
                                    }
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            achievement("flame.fill", "Current streak", "\(store.streak) days", AppTheme.coral)
                            achievement("trophy.fill", "Longest streak", "\(store.longestStreak) days", AppTheme.yellow)
                        }
                        achievement("character.book.closed.fill", "Letters learned", "\(store.learnedLetterIDs.count) of \(GeorgianLetter.all.count)", AppTheme.violet)
                        VStack(spacing: 0) {
                            HStack(spacing: 13) {
                                Image(systemName: appearance.icon)
                                    .frame(width: 25)
                                    .foregroundStyle(AppTheme.violet)
                                    .accessibilityHidden(true)
                                Text("Appearance").foregroundStyle(AppTheme.ink)
                                Spacer()
                                Picker("Appearance", selection: $appearance) {
                                    ForEach(AppearanceMode.allCases) { mode in
                                        Text(mode.title).tag(mode)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(AppTheme.secondary)
                            }
                            .padding(.vertical, 5)
                            Divider().padding(.leading, 48)
                            reminderSettings
                        }
                        .padding(.horizontal, 16).glassEffect(.regular, in: .rect(cornerRadius: 26))
                    }
                    .padding(20).padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isAvatarPickerPresented) {
                AvatarPicker(selectedAvatarID: $selectedAvatarID)
                    .presentationDetents([.height(390)])
                    .presentationDragIndicator(.visible)
            }
            .alert("Reminders unavailable", isPresented: Binding(
                get: { reminderError != nil },
                set: { if !$0 { reminderError = nil } }
            )) {
                Button("OK", role: .cancel) { reminderError = nil }
            } message: {
                Text(reminderError ?? "")
            }
        }
    }

    private var reminderDate: Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: reminderTimeMinutes / 60,
                minute: reminderTimeMinutes % 60,
                second: 0,
                of: Date()
            ) ?? Date()
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderTimeMinutes = (components.hour ?? 9) * 60 + (components.minute ?? 0)
            guard reminderEnabled else { return }
            Task {
                _ = await ReminderManager.setReminder(
                    enabled: true,
                    minutesAfterMidnight: reminderTimeMinutes,
                    hasSecuredStreakToday: store.hasSecuredStreakToday
                )
            }
        }
    }

    private var reminderSettings: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "bell.fill")
                    .frame(width: 25)
                    .foregroundStyle(AppTheme.violet)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily reminder").foregroundStyle(AppTheme.ink)
                    (reminderEnabled ? Text(reminderDate.wrappedValue, format: .dateTime.hour().minute()) : Text("Off"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Toggle("Daily reminder", isOn: Binding(
                    get: { reminderEnabled },
                    set: updateReminder
                ))
                .labelsHidden()
                .tint(AppTheme.coral)
            }
            .padding(.vertical, 11)

            if reminderEnabled {
                Divider().padding(.leading, 48)
                DatePicker(
                    "Reminder time",
                    selection: reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .foregroundStyle(AppTheme.ink)
                .padding(.leading, 38)
                .padding(.vertical, 11)
            }
        }
    }

    private func updateReminder(_ enabled: Bool) {
        Task {
            let scheduled = await ReminderManager.setReminder(
                enabled: enabled,
                minutesAfterMidnight: reminderTimeMinutes,
                hasSecuredStreakToday: store.hasSecuredStreakToday
            )
            if enabled && !scheduled {
                reminderEnabled = false
                reminderError = String(localized: "Allow notifications for Kartuli in Settings to receive your daily learning reminder.")
            } else {
                reminderEnabled = enabled
            }
        }
    }

    private func achievement(_ icon: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).font(.title2).foregroundStyle(color).accessibilityHidden(true)
            Text(title).font(.headline).foregroundStyle(AppTheme.ink)
            Text(detail).font(.caption).foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18).glassEffect(.regular, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

private struct AvatarPicker: View {
    @Binding var selectedAvatarID: String
    @Environment(\.dismiss) private var dismiss
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pick your Georgian sidekick")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(ProfileAvatar.allCases) { avatar in
                        Button {
                            selectedAvatarID = avatar.rawValue
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    ProfileAvatarImage(avatar: avatar, size: 76)
                                    if selectedAvatarID == avatar.rawValue {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.mint)
                                            .background(.white, in: Circle())
                                    }
                                }
                                Text(avatar.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(avatar.name))
                        .accessibilityAddTraits(selectedAvatarID == avatar.rawValue ? .isSelected : [])
                    }
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Choose avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
