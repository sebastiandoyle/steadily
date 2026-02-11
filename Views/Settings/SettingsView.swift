import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var showingPaywall = false
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                List {
                    // Premium section
                    premiumSection

                    // Preferences
                    preferencesSection

                    // Reminders
                    remindersSection

                    // Data
                    dataSection

                    // About
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your habits and progress. This cannot be undone.")
            }
        }
    }

    private var premiumSection: some View {
        Section {
            if subscriptionManager.isPremium {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.mutedGold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium Active")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.deepForest)

                        Text("Thank you for your support!")
                            .font(.caption)
                            .foregroundColor(AppColors.deepForest.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.sageGreen)
                }
            } else {
                Button(action: { showingPaywall = true }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.mutedGold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.deepForest)

                            Text("Unlimited habits, insights, and more")
                                .font(.caption)
                                .foregroundColor(AppColors.deepForest.opacity(0.6))
                        }

                        Spacer()

                        Text("7-day trial")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.sageGreen)
                            .cornerRadius(8)
                    }
                }
            }

            Button(action: {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.sageGreen)
                    Text("Restore Purchases")
                        .foregroundColor(AppColors.deepForest)
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $userPreferences.hapticFeedbackEnabled) {
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundColor(AppColors.sageGreen)
                    Text("Haptic Feedback")
                        .foregroundColor(AppColors.deepForest)
                }
            }
            .tint(AppColors.sageGreen)

            Toggle(isOn: $userPreferences.showStreakAnimations) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.softTerracotta)
                    Text("Streak Animations")
                        .foregroundColor(AppColors.deepForest)
                }
            }
            .tint(AppColors.sageGreen)

            Toggle(isOn: $userPreferences.weekStartsOnMonday) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.mutedGold)
                    Text("Week Starts on Monday")
                        .foregroundColor(AppColors.deepForest)
                }
            }
            .tint(AppColors.sageGreen)
        } header: {
            Text("Preferences")
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $userPreferences.reminderEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(AppColors.sageGreen)
                    Text("Daily Reminder")
                        .foregroundColor(AppColors.deepForest)
                }
            }
            .tint(AppColors.sageGreen)

            if userPreferences.reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = userPreferences.reminderHour
                            components.minute = userPreferences.reminderMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            userPreferences.reminderHour = components.hour ?? 9
                            userPreferences.reminderMinute = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .foregroundColor(AppColors.deepForest)
            }
        } header: {
            Text("Reminders")
        }
    }

    private var dataSection: some View {
        Section {
            if subscriptionManager.isPremium {
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppColors.sageGreen)
                        Text("Export Data")
                            .foregroundColor(AppColors.deepForest)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColors.deepForest.opacity(0.4))
                    Text("Export Data")
                        .foregroundColor(AppColors.deepForest.opacity(0.4))
                    Spacer()
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.sageGreen.opacity(0.5))
                        .cornerRadius(4)
                }
            }

            Button(action: { showingResetConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Reset All Data")
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Data")
        }
    }

    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://sebastiandoyle.github.io/steadily-privacy/privacy-policy.html")!) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(AppColors.sageGreen)
                    Text("Privacy Policy")
                        .foregroundColor(AppColors.deepForest)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(AppColors.deepForest.opacity(0.4))
                }
            }

            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(AppColors.sageGreen)
                    Text("Terms of Use")
                        .foregroundColor(AppColors.deepForest)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(AppColors.deepForest.opacity(0.4))
                }
            }

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(AppColors.sageGreen)
                Text("Version")
                    .foregroundColor(AppColors.deepForest)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppColors.deepForest.opacity(0.6))
            }
        } header: {
            Text("About")
        } footer: {
            VStack(spacing: 8) {
                Text("Made with 💚 for building better habits")
                    .font(.caption)
                    .foregroundColor(AppColors.deepForest.opacity(0.5))

                Text("© 2026 Sebastian Doyle")
                    .font(.caption2)
                    .foregroundColor(AppColors.deepForest.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }

    private func exportData() {
        // Export habits as JSON
        if let encoded = try? JSONEncoder().encode(habitStore.habits) {
            let json = String(data: encoded, encoding: .utf8) ?? ""
            // Share sheet would go here
            print(json)
        }
    }

    private func resetAllData() {
        habitStore.habits.removeAll()
        userPreferences.resetOnboarding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
        .environmentObject(UserPreferences())
}
