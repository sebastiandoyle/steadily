import SwiftUI

@main
struct SteadilyApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var userPreferences = UserPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .environmentObject(subscriptionManager)
                .environmentObject(userPreferences)
                .onAppear {
                    setupForScreenshots()
                }
        }
    }

    private func setupForScreenshots() {
        guard let mode = userPreferences.screenshotMode else { return }

        switch mode {
        case .onboarding:
            userPreferences.hasCompletedOnboarding = false
        case .today, .todayStreak:
            userPreferences.hasCompletedOnboarding = true
            habitStore.loadDemoData()
        case .habits:
            userPreferences.hasCompletedOnboarding = true
            habitStore.loadDemoData()
        case .insights, .insightsLocked:
            userPreferences.hasCompletedOnboarding = true
            habitStore.loadDemoData()
        case .paywall:
            userPreferences.hasCompletedOnboarding = false
        }
    }
}
