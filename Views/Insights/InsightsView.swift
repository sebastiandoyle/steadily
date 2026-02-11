import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if subscriptionManager.isPremium {
                    premiumContent
                } else {
                    lockedContent
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Premium Content
    private var premiumContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Summary cards
                summaryCards

                // Completion chart
                completionChart

                // Best performing habits
                bestHabitsSection

                // Weekly heatmap
                weeklyHeatmap

                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Streak",
                value: "\(habitStore.totalStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: AppColors.softTerracotta
            )

            SummaryCard(
                title: "This Week",
                value: "\(Int(weeklyCompletionRate * 100))%",
                subtitle: "completed",
                icon: "chart.bar.fill",
                color: AppColors.sageGreen
            )

            SummaryCard(
                title: "Active",
                value: "\(habitStore.activeHabits.count)",
                subtitle: "habits",
                icon: "leaf.fill",
                color: AppColors.mutedGold
            )
        }
    }

    private var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        let today = Date()
        var totalScheduled = 0
        var totalCompleted = 0

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let scheduled = habitStore.habitsScheduledFor(date: date)
                let completed = habitStore.completedHabitsFor(date: date)
                totalScheduled += scheduled.count
                totalCompleted += completed.count
            }
        }

        return totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0
    }

    private var completionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            Chart {
                ForEach(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Rate", item.rate)
                    )
                    .foregroundStyle(AppColors.sageGreen.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%")
                                .font(.caption2)
                                .foregroundColor(AppColors.deepForest.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var chartData: [(date: Date, rate: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [(date: Date, rate: Double)] = []

        let days = selectedTimeRange == .week ? 7 : (selectedTimeRange == .month ? 30 : 365)

        for dayOffset in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let scheduled = habitStore.habitsScheduledFor(date: date)
                let completed = habitStore.completedHabitsFor(date: date)
                let rate = scheduled.isEmpty ? 0 : Double(completed.count) / Double(scheduled.count)
                data.append((date: date, rate: rate))
            }
        }

        return data
    }

    private var bestHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            ForEach(habitStore.activeHabits.sorted { $0.completionRate > $1.completionRate }.prefix(3)) { habit in
                HStack {
                    Text(habit.emoji)
                        .font(.title3)

                    Text(habit.name)
                        .font(.subheadline)
                        .foregroundColor(AppColors.deepForest)

                    Spacer()

                    Text("\(Int(habit.completionRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.sageGreen)
                }
                .padding(.vertical, 8)

                if habit.id != habitStore.activeHabits.sorted(by: { $0.completionRate > $1.completionRate }).prefix(3).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var weeklyHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Pattern")
                .font(.headline)
                .foregroundColor(AppColors.deepForest)

            HStack(spacing: 8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(AppColors.deepForest.opacity(0.6))

                        Circle()
                            .fill(colorForDay(day))
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func colorForDay(_ day: String) -> Color {
        // Calculate average completion rate for this day of week
        let rate = 0.7 // Placeholder - would calculate from actual data
        return AppColors.sageGreen.opacity(rate)
    }

    // MARK: - Locked Content
    private var lockedContent: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.sageGreen.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.sageGreen)
            }

            VStack(spacing: 12) {
                Text("Unlock Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.deepForest)

                Text("See detailed analytics, trends, and patterns\nto understand your habits better.")
                    .font(.body)
                    .foregroundColor(AppColors.deepForest.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Preview cards (blurred)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PreviewCard(title: "Completion", value: "87%", color: AppColors.sageGreen)
                    PreviewCard(title: "Streak", value: "12", color: AppColors.softTerracotta)
                }
                .blur(radius: 3)

                RoundedRectangle(cornerRadius: 15)
                    .fill(AppColors.cardBackground)
                    .frame(height: 150)
                    .overlay(
                        Text("📊")
                            .font(.system(size: 40))
                    )
                    .blur(radius: 3)
            }
            .padding()

            Button(action: { showingPaywall = true }) {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text("Unlock with Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.sageGreen)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.deepForest)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(AppColors.deepForest.opacity(0.6))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppColors.deepForest.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct PreviewCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.deepForest.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
    }
}

#Preview {
    InsightsView()
        .environmentObject(HabitStore())
        .environmentObject(SubscriptionManager())
}
