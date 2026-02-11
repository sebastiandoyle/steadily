import SwiftUI

struct EditHabitView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    let habit: Habit

    @State private var name: String
    @State private var selectedEmoji: String
    @State private var frequency: HabitFrequency
    @State private var selectedDays: Set<Int>
    @State private var isTally: Bool
    @State private var tallyTarget: Int
    @State private var selectedColor: String
    @State private var showDeleteConfirmation = false

    private let emojis = ["✨", "🧘", "💪", "📚", "💧", "📝", "🚶", "😴", "🍎", "🎯", "🌱", "☀️", "🏃", "🧠", "❤️", "🎨"]
    private let colors = ["7D9B76", "D4A574", "C9B896", "5BA4A4", "8B7355", "9B7D9B", "7D8B9B", "A47D7D"]
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedEmoji = State(initialValue: habit.emoji)
        _frequency = State(initialValue: habit.frequency)
        _selectedDays = State(initialValue: habit.targetDays)
        _isTally = State(initialValue: habit.isTally)
        _tallyTarget = State(initialValue: habit.tallyTarget)
        _selectedColor = State(initialValue: habit.color)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Stats card
                        statsCard

                        // Edit form
                        editSection

                        // Frequency
                        frequencySection

                        // Tally option
                        tallySection

                        // Color picker
                        colorSection

                        // Archive/Delete
                        dangerZone
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    habitStore.deleteHabit(habit)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete '\(habit.name)' and all its history. This cannot be undone.")
            }
        }
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                StatItem(value: "\(habit.currentStreak)", label: "Current Streak", icon: "flame.fill", color: AppColors.softTerracotta)
                StatItem(value: "\(habit.longestStreak)", label: "Best Streak", icon: "trophy.fill", color: AppColors.mutedGold)
                StatItem(value: "\(Int(habit.completionRate * 100))%", label: "Completion", icon: "chart.bar.fill", color: AppColors.sageGreen)
            }

            // Weekly mini calendar
            weeklyCalendar
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var weeklyCalendar: some View {
        let calendar = Calendar.current
        let today = Date()
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }

        return HStack(spacing: 8) {
            ForEach(days, id: \.self) { date in
                let day = calendar.startOfDay(for: date)
                let isToday = calendar.isDateInToday(date)
                let isCompleted = habit.isTally ?
                    (habit.tallyCounts[day] ?? 0) >= habit.tallyTarget :
                    habit.completions[day] == true

                VStack(spacing: 4) {
                    Text(dayLabel(for: date))
                        .font(.caption2)
                        .foregroundColor(AppColors.deepForest.opacity(0.5))

                    Circle()
                        .fill(isCompleted ? AppColors.completedGreen : (isToday ? AppColors.sageGreen.opacity(0.2) : Color.gray.opacity(0.1)))
                        .frame(width: 28, height: 28)
                        .overlay(
                            isCompleted ?
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            : nil
                        )
                        .overlay(
                            isToday && !isCompleted ?
                            Circle()
                                .stroke(AppColors.sageGreen, lineWidth: 2)
                            : nil
                        )
                }
            }
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private var editSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            HStack(spacing: 12) {
                Menu {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji)
                        }
                    }
                } label: {
                    Text(selectedEmoji)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                }

                TextField("Habit name", text: $name)
                    .font(.body)
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            Picker("Frequency", selection: $frequency) {
                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq)
                }
            }
            .pickerStyle(.segmented)

            if frequency == .specificDays {
                HStack(spacing: 8) {
                    ForEach(0..<7) { day in
                        Button(action: {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }) {
                            Text(dayNames[day])
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedDays.contains(day) ? .white : AppColors.deepForest)
                                .frame(width: 40, height: 40)
                                .background(selectedDays.contains(day) ? AppColors.sageGreen : AppColors.cardBackground)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    private var tallySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isTally) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Count-based habit")
                        .font(.body)
                        .foregroundColor(AppColors.deepForest)
                    Text("Track multiple completions per day")
                        .font(.caption)
                        .foregroundColor(AppColors.deepForest.opacity(0.6))
                }
            }
            .tint(AppColors.sageGreen)

            if isTally {
                HStack {
                    Text("Daily target:")
                        .font(.subheadline)
                        .foregroundColor(AppColors.deepForest)

                    Spacer()

                    Stepper("\(tallyTarget)", value: $tallyTarget, in: 1...99)
                        .labelsHidden()

                    Text("\(tallyTarget)")
                        .font(.headline)
                        .foregroundColor(AppColors.deepForest)
                        .frame(width: 40)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? AppColors.deepForest : Color.clear, lineWidth: 2)
                            )
                            .overlay(
                                selectedColor == color ?
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                : nil
                            )
                    }
                }
            }
        }
    }

    private var dangerZone: some View {
        VStack(spacing: 12) {
            if habit.isArchived {
                Button(action: {
                    habitStore.restoreHabit(habit)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Restore Habit")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.sageGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.sageGreen.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    habitStore.archiveHabit(habit)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "archivebox")
                        Text("Archive Habit")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.deepForest.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.deepForest.opacity(0.05))
                    .cornerRadius(12)
                }
            }

            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Habit")
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private func saveChanges() {
        var updated = habit
        updated.name = name
        updated.emoji = selectedEmoji
        updated.frequency = frequency
        updated.targetDays = frequency == .specificDays ? selectedDays : Set(0...6)
        updated.isTally = isTally
        updated.tallyTarget = tallyTarget
        updated.color = selectedColor

        habitStore.updateHabit(updated)
        dismiss()
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.deepForest)

            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.deepForest.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EditHabitView(habit: Habit(name: "Test", emoji: "🧘"))
        .environmentObject(HabitStore())
}
