import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var currentPage = 0
    @State private var selectedGoals: Set<String> = []
    @State private var firstHabitName = ""
    @State private var firstHabitEmoji = "✨"
    @State private var showPaywall = false

    private let goals = [
        ("🧘", "Build healthy routines"),
        ("💪", "Get more exercise"),
        ("📚", "Learn something new"),
        ("😴", "Improve my sleep"),
        ("🎯", "Stay focused"),
        ("🌱", "Grow personally"),
    ]

    private let quickHabits = [
        ("🧘", "Morning Meditation"),
        ("💪", "Daily Exercise"),
        ("📚", "Read 20 pages"),
        ("💧", "Drink 8 glasses"),
        ("📝", "Journal"),
        ("🚶", "Walk 10k steps"),
    ]

    var body: some View {
        ZStack {
            AppColors.onboardingGradient
                .ignoresSafeArea()

            VStack {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top)

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    goalsPage.tag(1)
                    firstHabitPage.tag(2)
                    completePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                completeOnboarding()
            }
        }
    }

    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Animated logo
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text("Small steps.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Big changes.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.mutedGold)

                Text("Build habits that work with your life,\nnot against it.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()

            Button(action: { withAnimation { currentPage = 1 } }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(AppColors.deepForest)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Page 2: Goals
    private var goalsPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What would you love")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("to achieve?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.mutedGold)
            }
            .padding(.top, 40)

            Text("Select all that apply")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals, id: \.1) { emoji, goal in
                    GoalButton(
                        emoji: emoji,
                        text: goal,
                        isSelected: selectedGoals.contains(goal)
                    ) {
                        if selectedGoals.contains(goal) {
                            selectedGoals.remove(goal)
                        } else {
                            selectedGoals.insert(goal)
                        }
                    }
                }
            }
            .padding()

            Spacer()

            Button(action: { withAnimation { currentPage = 2 } }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(AppColors.deepForest)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Page 3: First Habit
    private var firstHabitPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create your")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("first habit")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.mutedGold)
            }
            .padding(.top, 40)

            Text("Start with just one. You can add more later.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            // Quick picks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickHabits, id: \.1) { emoji, name in
                        Button(action: {
                            firstHabitEmoji = emoji
                            firstHabitName = name
                        }) {
                            VStack(spacing: 8) {
                                Text(emoji)
                                    .font(.title)
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding()
                            .frame(width: 100)
                            .background(firstHabitName == name ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(firstHabitName == name ? Color.white : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Custom input
            VStack(alignment: .leading, spacing: 8) {
                Text("Or create your own:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Text(firstHabitEmoji)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)

                    TextField("Habit name", text: $firstHabitName)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()

            Spacer()

            Button(action: createFirstHabitAndContinue) {
                Text("Create Habit")
                    .font(.headline)
                    .foregroundColor(AppColors.deepForest)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(firstHabitName.isEmpty ? Color.white.opacity(0.5) : Color.white)
                    .cornerRadius(15)
            }
            .disabled(firstHabitName.isEmpty)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Page 4: Complete
    private var completePage: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.mutedGold)
            }

            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Your first habit '\(firstHabitName)' is ready.\nLet's make it stick.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: { showPaywall = true }) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .foregroundColor(AppColors.deepForest)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                }

                Button(action: completeOnboarding) {
                    Text("Continue with Free")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private func createFirstHabitAndContinue() {
        let habit = Habit(name: firstHabitName, emoji: firstHabitEmoji)
        habitStore.addHabit(habit)
        userPreferences.firstHabitName = firstHabitName
        withAnimation { currentPage = 3 }
    }

    private func completeOnboarding() {
        userPreferences.hasCompletedOnboarding = true
    }
}

struct GoalButton: View {
    let emoji: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(emoji)
                    .font(.title2)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(HabitStore())
        .environmentObject(UserPreferences())
}
