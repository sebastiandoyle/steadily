import Foundation
import SwiftUI

class UserPreferences: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("selectedTheme") var selectedTheme = "default"
    @AppStorage("reminderEnabled") var reminderEnabled = true
    @AppStorage("reminderHour") var reminderHour = 9
    @AppStorage("reminderMinute") var reminderMinute = 0
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled = true
    @AppStorage("showStreakAnimations") var showStreakAnimations = true
    @AppStorage("weekStartsOnMonday") var weekStartsOnMonday = false

    // First habit name created during onboarding
    @AppStorage("firstHabitName") var firstHabitName = ""

    // Screenshot mode support
    var screenshotMode: ScreenshotMode? {
        if let mode = ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] {
            return ScreenshotMode(rawValue: mode)
        }
        return nil
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        firstHabitName = ""
    }
}

enum ScreenshotMode: String {
    case onboarding
    case today
    case todayStreak = "today_streak"
    case habits
    case insights
    case insightsLocked = "insights_locked"
    case paywall
}
