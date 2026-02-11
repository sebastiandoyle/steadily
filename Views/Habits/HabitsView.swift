import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddHabit = false
    @State private var showingPaywall = false
    @State private var editingHabit: Habit?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if habitStore.activeHabits.isEmpty {
                            emptyState
                        } else {
                            activeHabitsSection
                        }

                        if !habitStore.archivedHabits.isEmpty {
                            archivedSection
                        }

                        // Free tier info
                        if !subscriptionManager.isPremium {
                            freeTierCard
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
            .navigationTitle("Habits")
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $editingHabit) { habit in
                EditHabitView(habit: habit)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(AppColors.sageGreen.opacity(0.5))

            Text("No habits yet")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            Text("Start building your routine with your first habit")
                .font(.subheadline)
                .foregroundColor(AppColors.deepForest.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: { showingAddHabit = true }) {
                Text("Create First Habit")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.sageGreen)
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 60)
    }

    private var activeHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Habits")
                    .font(.headline)
                    .foregroundColor(AppColors.deepForest)

                Spacer()

                if !subscriptionManager.isPremium {
                    Text("\(habitStore.activeHabits.count)/3")
                        .font(.caption)
                        .foregroundColor(AppColors.deepForest.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.sageGreen.opacity(0.1))
                        .cornerRadius(10)
                }
            }

            ForEach(habitStore.activeHabits) { habit in
                HabitRowView(habit: habit) {
                    editingHabit = habit
                }
            }
        }
    }

    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Archived")
                .font(.headline)
                .foregroundColor(AppColors.deepForest.opacity(0.7))

            ForEach(habitStore.archivedHabits) { habit in
                HabitRowView(habit: habit, isArchived: true) {
                    editingHabit = habit
                }
            }
        }
    }

    private var freeTierCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(AppColors.mutedGold)
                Text("Unlock Unlimited Habits")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.deepForest)
            }

            Text("Free plan includes 3 habits. Upgrade for unlimited habits, insights, and more.")
                .font(.caption)
                .foregroundColor(AppColors.deepForest.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: { showingPaywall = true }) {
                Text("Try Free for 7 Days")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.sageGreen)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(AppColors.mutedGold.opacity(0.1))
        .cornerRadius(15)
    }

    private var addButton: some View {
        Button(action: {
            if habitStore.canAddHabit(isPremium: subscriptionManager.isPremium) {
                showingAddHabit = true
            } else {
                showingPaywall = true
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

struct HabitRowView: View {
    let habit: Habit
    var isArchived: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(habit.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: habit.color).opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isArchived ? AppColors.deepForest.opacity(0.5) : AppColors.deepForest)

                    HStack(spacing: 8) {
                        // Frequency label
                        Text(habit.frequency.rawValue)
                            .font(.caption)
                            .foregroundColor(AppColors.deepForest.opacity(0.5))

                        if habit.currentStreak > 0 && !isArchived {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.softTerracotta)
                                Text("\(habit.currentStreak)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.softTerracotta)
                            }
                        }
                    }
                }

                Spacer()

                // Completion rate
                if !isArchived {
                    Text("\(Int(habit.completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.sageGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.sageGreen.opacity(0.1))
                        .cornerRadius(8)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.deepForest.opacity(0.3))
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.03), radius: 5)
            .opacity(isArchived ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HabitsView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
}
