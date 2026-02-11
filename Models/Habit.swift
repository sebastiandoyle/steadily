import Foundation

struct Habit: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var emoji: String
    var createdAt: Date = Date()
    var frequency: HabitFrequency = .daily
    var targetDays: Set<Int> = Set(0...6) // 0 = Sunday, 6 = Saturday
    var reminderTime: Date?
    var isArchived: Bool = false
    var color: String = "7D9B76" // Default sage green

    // Completion tracking
    var completions: [Date: Bool] = [:]

    // For tally-type habits
    var isTally: Bool = false
    var tallyTarget: Int = 1
    var tallyCounts: [Date: Int] = [:]

    // Computed properties
    var currentStreak: Int {
        calculateStreak()
    }

    var longestStreak: Int {
        calculateLongestStreak()
    }

    var completionRate: Double {
        calculateCompletionRate()
    }

    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if isTally {
            return (tallyCounts[today] ?? 0) >= tallyTarget
        }
        return completions[today] == true
    }

    var todayTallyCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tallyCounts[today] ?? 0
    }

    // MARK: - Methods

    mutating func toggleCompletion(for date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        if isTally {
            let current = tallyCounts[day] ?? 0
            if current >= tallyTarget {
                tallyCounts[day] = 0
            } else {
                tallyCounts[day] = current + 1
            }
        } else {
            completions[day] = !(completions[day] ?? false)
        }
    }

    mutating func incrementTally(for date: Date = Date()) {
        guard isTally else { return }
        let day = Calendar.current.startOfDay(for: date)
        let current = tallyCounts[day] ?? 0
        tallyCounts[day] = current + 1
    }

    mutating func setCompletion(_ completed: Bool, for date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        completions[day] = completed
    }

    func isScheduledFor(date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date) - 1 // Convert to 0-6
        switch frequency {
        case .daily:
            return true
        case .specificDays:
            return targetDays.contains(weekday)
        case .weeklyGoal:
            return true // Always show, track toward weekly goal
        }
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if completed today first
        if !isCompleted(on: checkDate) && !isScheduledFor(date: checkDate) {
            // If not scheduled today, start from yesterday
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else if !isCompleted(on: checkDate) {
            // Not completed today when it should be
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        while true {
            if isScheduledFor(date: checkDate) {
                if isCompleted(on: checkDate) {
                    streak += 1
                } else {
                    break
                }
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!

            // Don't go past creation date
            if checkDate < calendar.startOfDay(for: createdAt) {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 0

        let sortedDates = completions.keys.sorted()
        guard let firstDate = sortedDates.first else { return 0 }

        var checkDate = calendar.startOfDay(for: firstDate)
        let today = calendar.startOfDay(for: Date())

        while checkDate <= today {
            if isScheduledFor(date: checkDate) {
                if isCompleted(on: checkDate) {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
        }

        return longestStreak
    }

    private func calculateCompletionRate() -> Double {
        let calendar = Calendar.current
        var scheduledDays = 0
        var completedDays = 0

        var checkDate = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())

        while checkDate <= today {
            if isScheduledFor(date: checkDate) {
                scheduledDays += 1
                if isCompleted(on: checkDate) {
                    completedDays += 1
                }
            }
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
        }

        return scheduledDays > 0 ? Double(completedDays) / Double(scheduledDays) : 0
    }

    private func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        if isTally {
            return (tallyCounts[day] ?? 0) >= tallyTarget
        }
        return completions[day] == true
    }
}

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case specificDays = "Specific Days"
    case weeklyGoal = "Weekly Goal"
}
