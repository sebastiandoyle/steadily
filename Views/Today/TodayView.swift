import SwiftUI

struct TodayView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddHabit = false
    @State private var animateProgress = false

    private var todayHabits: [Habit] {
        habitStore.habitsScheduledFor(date: Date())
    }

    private var completedCount: Int {
        habitStore.completedHabitsFor(date: Date()).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Progress header
                        progressHeader

                        // Streak card (if any)
                        if habitStore.totalStreak > 0 {
                            streakCard
                        }

                        // Today's habits
                        if todayHabits.isEmpty {
                            emptyState
                        } else {
                            habitsSection
                        }

                        Spacer(minLength: 80)
                    }
                    .padding()
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateProgress = true
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(AppColors.sageGreen.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: animateProgress ? habitStore.todayProgress : 0)
                    .stroke(
                        AppColors.sageGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: habitStore.todayProgress)

                VStack(spacing: 4) {
                    Text("\(completedCount)/\(todayHabits.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.deepForest)

                    Text("completed")
                        .font(.caption)
                        .foregroundColor(AppColors.deepForest.opacity(0.7))
                }
            }

            // Motivational message
            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundColor(AppColors.deepForest.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var motivationalMessage: String {
        let progress = habitStore.todayProgress
        if progress == 0 {
            return "Start small. Every step counts. 🌱"
        } else if progress < 0.5 {
            return "You're making progress! Keep it up. 💚"
        } else if progress < 1.0 {
            return "Almost there! You've got this. ✨"
        } else {
            return "Amazing! All habits complete! 🎉"
        }
    }

    private var streakCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(AppColors.softTerracotta)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(habitStore.totalStreak) day streak")
                    .font(.headline)
                    .foregroundColor(AppColors.deepForest)

                Text("Keep the momentum going!")
                    .font(.caption)
                    .foregroundColor(AppColors.deepForest.opacity(0.7))
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppColors.softTerracotta.opacity(0.15), AppColors.mutedGold.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            ForEach(todayHabits) { habit in
                HabitCard(habit: habit) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        habitStore.toggleCompletion(for: habit)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.sageGreen.opacity(0.5))

            Text("No habits scheduled for today")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            Text("Tap + to add your first habit")
                .font(.subheadline)
                .foregroundColor(AppColors.deepForest.opacity(0.7))

            Button(action: { showingAddHabit = true }) {
                Text("Add Habit")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.sageGreen)
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
    }

    private var addButton: some View {
        Button(action: {
            if habitStore.canAddHabit(isPremium: subscriptionManager.isPremium) {
                showingAddHabit = true
            } else {
                // Show paywall
                showingAddHabit = true // Will handle in AddHabitView
            }
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.sageGreen)
                .clipShape(Circle())
                .shadow(color: AppColors.sageGreen.opacity(0.4), radius: 8, y: 4)
        }
    }
}

struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedToday ? AppColors.completedGreen : AppColors.sageGreen.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    if habit.isCompletedToday {
                        Circle()
                            .fill(AppColors.completedGreen)
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)

                // Emoji
                Text(habit.emoji)
                    .font(.title2)

                // Name and streak
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.deepForest)
                        .strikethrough(habit.isCompletedToday, color: AppColors.deepForest.opacity(0.5))

                    if habit.isTally {
                        Text("\(habit.todayTallyCount)/\(habit.tallyTarget)")
                            .font(.caption)
                            .foregroundColor(AppColors.deepForest.opacity(0.6))
                    } else if habit.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(AppColors.softTerracotta)
                            Text("\(habit.currentStreak) days")
                                .font(.caption)
                                .foregroundColor(AppColors.deepForest.opacity(0.6))
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.03), radius: 5)
            .opacity(habit.isCompletedToday ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    TodayView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
}
