import XCTest
@testable import Steadily

final class SteadilyTests: XCTestCase {

    // MARK: - Habit Tests

    func testHabitCreation() {
        let habit = Habit(name: "Test Habit", emoji: "✨")

        XCTAssertEqual(habit.name, "Test Habit")
        XCTAssertEqual(habit.emoji, "✨")
        XCTAssertFalse(habit.isCompletedToday)
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func testHabitCompletion() {
        var habit = Habit(name: "Test", emoji: "🧘")

        XCTAssertFalse(habit.isCompletedToday)

        habit.toggleCompletion()

        XCTAssertTrue(habit.isCompletedToday)

        habit.toggleCompletion()

        XCTAssertFalse(habit.isCompletedToday)
    }

    func testTallyHabit() {
        var habit = Habit(name: "Water", emoji: "💧")
        habit.isTally = true
        habit.tallyTarget = 8

        XCTAssertFalse(habit.isCompletedToday)
        XCTAssertEqual(habit.todayTallyCount, 0)

        for _ in 0..<8 {
            habit.incrementTally()
        }

        XCTAssertTrue(habit.isCompletedToday)
        XCTAssertEqual(habit.todayTallyCount, 8)
    }

    func testStreakCalculation() {
        var habit = Habit(name: "Exercise", emoji: "💪")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Complete for 5 consecutive days
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                habit.completions[date] = true
            }
        }

        XCTAssertEqual(habit.currentStreak, 5)
    }

    func testStreakBroken() {
        var habit = Habit(name: "Read", emoji: "📚")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Complete today
        habit.completions[today] = true

        // Skip yesterday
        // Complete 2 days ago
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) {
            habit.completions[twoDaysAgo] = true
        }

        XCTAssertEqual(habit.currentStreak, 1) // Only today counts
    }

    // MARK: - HabitStore Tests

    @MainActor
    func testHabitStoreAddHabit() async {
        let store = HabitStore()

        let habit = Habit(name: "New Habit", emoji: "🌟")
        store.addHabit(habit)

        XCTAssertEqual(store.habits.count, 1)
        XCTAssertEqual(store.habits.first?.name, "New Habit")
    }

    @MainActor
    func testFreeUserHabitLimit() async {
        let store = HabitStore()

        // Free users can have 3 habits
        XCTAssertTrue(store.canAddHabit(isPremium: false))

        store.addHabit(Habit(name: "Habit 1", emoji: "1️⃣"))
        store.addHabit(Habit(name: "Habit 2", emoji: "2️⃣"))
        store.addHabit(Habit(name: "Habit 3", emoji: "3️⃣"))

        XCTAssertFalse(store.canAddHabit(isPremium: false))
        XCTAssertTrue(store.canAddHabit(isPremium: true))
    }

    @MainActor
    func testArchiveHabit() async {
        let store = HabitStore()

        let habit = Habit(name: "Archive Test", emoji: "📦")
        store.addHabit(habit)

        XCTAssertEqual(store.activeHabits.count, 1)
        XCTAssertEqual(store.archivedHabits.count, 0)

        store.archiveHabit(habit)

        XCTAssertEqual(store.activeHabits.count, 0)
        XCTAssertEqual(store.archivedHabits.count, 1)
    }

    @MainActor
    func testTodayProgress() async {
        let store = HabitStore()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var habit1 = Habit(name: "Habit 1", emoji: "1️⃣")
        habit1.completions[today] = true

        var habit2 = Habit(name: "Habit 2", emoji: "2️⃣")
        habit2.completions[today] = false

        store.addHabit(habit1)
        store.addHabit(habit2)

        XCTAssertEqual(store.todayProgress, 0.5, accuracy: 0.01)
    }

    // MARK: - Frequency Tests

    func testDailyFrequency() {
        let habit = Habit(name: "Daily", emoji: "📅")

        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        XCTAssertTrue(habit.isScheduledFor(date: today))
        XCTAssertTrue(habit.isScheduledFor(date: tomorrow))
    }

    func testSpecificDaysFrequency() {
        var habit = Habit(name: "Weekdays", emoji: "📅")
        habit.frequency = .specificDays
        habit.targetDays = [1, 2, 3, 4, 5] // Mon-Fri

        let calendar = Calendar.current

        // Find a Monday
        var components = DateComponents()
        components.weekday = 2 // Monday
        let monday = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)!

        // Find a Sunday
        components.weekday = 1 // Sunday
        let sunday = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)!

        XCTAssertTrue(habit.isScheduledFor(date: monday))
        XCTAssertFalse(habit.isScheduledFor(date: sunday))
    }

    // MARK: - Completion Rate Tests

    func testCompletionRateCalculation() {
        var habit = Habit(name: "Test", emoji: "📊")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Set creation date to 10 days ago
        habit.createdAt = calendar.date(byAdding: .day, value: -9, to: today)!

        // Complete 7 out of 10 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                habit.completions[date] = true
            }
        }

        XCTAssertEqual(habit.completionRate, 0.7, accuracy: 0.01)
    }
}
