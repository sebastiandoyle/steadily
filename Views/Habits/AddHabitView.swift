import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedEmoji = "✨"
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Int> = Set(0...6)
    @State private var isTally = false
    @State private var tallyTarget = 1
    @State private var selectedColor = "7D9B76"
    @State private var showingPaywall = false

    private let popularHabits = [
        ("🧘", "Meditate"),
        ("💪", "Exercise"),
        ("📚", "Read"),
        ("💧", "Drink water"),
        ("📝", "Journal"),
        ("🚶", "Walk 10k steps"),
        ("😴", "Sleep 8 hours"),
        ("🍎", "Eat healthy"),
    ]

    private let emojis = ["✨", "🧘", "💪", "📚", "💧", "📝", "🚶", "😴", "🍎", "🎯", "🌱", "☀️", "🏃", "🧠", "❤️", "🎨"]

    private let colors = ["7D9B76", "D4A574", "C9B896", "5BA4A4", "8B7355", "9B7D9B", "7D8B9B", "A47D7D"]

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Quick picks
                        quickPicksSection

                        // Custom habit form
                        customHabitSection

                        // Frequency
                        frequencySection

                        // Tally option
                        tallySection

                        // Color picker
                        colorSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var quickPicksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(popularHabits, id: \.1) { emoji, habitName in
                    Button(action: {
                        selectedEmoji = emoji
                        name = habitName
                    }) {
                        HStack(spacing: 8) {
                            Text(emoji)
                                .font(.title3)
                            Text(habitName)
                                .font(.subheadline)
                                .foregroundColor(AppColors.deepForest)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(name == habitName ? AppColors.sageGreen.opacity(0.2) : AppColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(name == habitName ? AppColors.sageGreen : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var customHabitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Or Create Custom")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            HStack(spacing: 12) {
                // Emoji picker
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

                // Name field
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

            // Frequency picker
            Picker("Frequency", selection: $frequency) {
                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq)
                }
            }
            .pickerStyle(.segmented)

            // Specific days (if applicable)
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

    private func saveHabit() {
        var habit = Habit(name: name, emoji: selectedEmoji)
        habit.frequency = frequency
        habit.targetDays = frequency == .specificDays ? selectedDays : Set(0...6)
        habit.isTally = isTally
        habit.tallyTarget = tallyTarget
        habit.color = selectedColor

        habitStore.addHabit(habit)
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
}
