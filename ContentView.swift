import SwiftUI

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var userPreferences: UserPreferences

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !userPreferences.hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppColors.sageGreen)
        .onAppear {
            setupTabBarAppearance()
            handleScreenshotMode()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.warmCream)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func handleScreenshotMode() {
        guard let mode = userPreferences.screenshotMode else { return }

        switch mode {
        case .today, .todayStreak:
            selectedTab = 0
        case .habits:
            selectedTab = 1
        case .insights, .insightsLocked:
            selectedTab = 2
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
        .environmentObject(UserPreferences())
}
