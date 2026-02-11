import Foundation
import SwiftUI

@MainActor
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []

    private let saveKey = "steadily_habits"
    private let maxFreeHabits = 3

    init() {
        loadHabits()
    }

    // MARK: - Free tier limitations

    func canAddHabit(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return activeHabits.count < maxFreeHabits
    }

    var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }

    // MARK: - CRUD Operations

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }

    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }

    func archiveHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isArchived = true
            saveHabits()
        }
    }

    func restoreHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isArchived = false
            saveHabits()
        }
    }

    // MARK: - Completion

    func toggleCompletion(for habit: Habit, on date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].toggleCompletion(for: date)
            saveHabits()
        }
    }

    func incrementTally(for habit: Habit, on date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].incrementTally(for: date)
            saveHabits()
        }
    }

    // MARK: - Statistics

    func habitsScheduledFor(date: Date) -> [Habit] {
        activeHabits.filter { $0.isScheduledFor(date: date) }
    }

    func completedHabitsFor(date: Date) -> [Habit] {
        let day = Calendar.current.startOfDay(for: date)
        return habitsScheduledFor(date: date).filter { habit in
            if habit.isTally {
                return (habit.tallyCounts[day] ?? 0) >= habit.tallyTarget
            }
            return habit.completions[day] == true
        }
    }

    var todayProgress: Double {
        let today = Date()
        let scheduled = habitsScheduledFor(date: today)
        guard !scheduled.isEmpty else { return 1.0 }
        let completed = completedHabitsFor(date: today)
        return Double(completed.count) / Double(scheduled.count)
    }

    var totalStreak: Int {
        // Total consecutive days where ALL habits were completed
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let scheduled = habitsScheduledFor(date: checkDate)
            if scheduled.isEmpty { break }

            let completed = completedHabitsFor(date: checkDate)
            if completed.count == scheduled.count {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if checkDate == calendar.startOfDay(for: Date()) {
                // Today not complete yet, check yesterday
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Persistence

    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }

    // MARK: - Demo Data for Screenshots

    func loadDemoData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var morningMeditation = Habit(name: "Morning Meditation", emoji: "🧘")
        morningMeditation.color = "7D9B76"
        // Complete for past 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                morningMeditation.completions[date] = true
            }
        }

        var exercise = Habit(name: "Exercise", emoji: "💪")
        exercise.color = "D4A574"
        // Complete for past 5 days
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                exercise.completions[date] = true
            }
        }

        var reading = Habit(name: "Read 20 pages", emoji: "📚")
        reading.color = "C9B896"
        // Complete for past 12 days
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                reading.completions[date] = true
            }
        }

        var water = Habit(name: "Drink 8 glasses", emoji: "💧")
        water.isTally = true
        water.tallyTarget = 8
        water.color = "5BA4A4"
        water.tallyCounts[today] = 5

        var journaling = Habit(name: "Journal", emoji: "📝")
        journaling.color = "8B7355"
        journaling.completions[today] = false // Not yet completed
        for i in 1..<10 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                journaling.completions[date] = true
            }
        }

        habits = [morningMeditation, exercise, reading, water, journaling]
        saveHabits()
    }
}
