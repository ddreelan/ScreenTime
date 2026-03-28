import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedRange: Int = 7

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Range Picker
                    Picker("Range", selection: $selectedRange) {
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Summary Cards
                    HStack(spacing: 12) {
                        AnalyticsSummaryCard(
                            title: "Avg Daily Use",
                            value: formatTime(averageDailyUse),
                            icon: "clock",
                            color: .blue
                        )
                        AnalyticsSummaryCard(
                            title: "Avg Earned",
                            value: formatTime(averageDailyEarned),
                            icon: "plus.circle",
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Weekly bar chart
                    BarChartView(summaries: recentSummaries, title: "Daily Usage")
                        .frame(height: 200)
                        .padding(.horizontal)

                    // App breakdown
                    AppUsageBreakdownView()
                        .padding(.horizontal)

                    // Achievements
                    AchievementsView(achievements: dataStore.achievements)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Analytics")
        }
    }

    private var recentSummaries: [DailyScreenTimeSummary] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange, to: Date()) ?? Date()
        return dataStore.weeklyHistory
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    private var averageDailyUse: TimeInterval {
        guard !recentSummaries.isEmpty else { return 0 }
        return recentSummaries.reduce(0) { $0 + $1.totalUsed } / Double(recentSummaries.count)
    }

    private var averageDailyEarned: TimeInterval {
        guard !recentSummaries.isEmpty else { return 0 }
        return recentSummaries.reduce(0) { $0 + $1.totalEarned } / Double(recentSummaries.count)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct AnalyticsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct BarChartView: View {
    let summaries: [DailyScreenTimeSummary]
    let title: String

    private let maxValue: TimeInterval = 4 * 3600

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(summaries) { summary in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            // Allocated bar (background)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 140)

                            // Used bar
                            VStack(spacing: 0) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor(for: summary))
                                    .frame(height: CGFloat(summary.totalUsed / maxValue) * 140)
                            }
                            .frame(height: 140)
                        }

                        Text(dayLabel(for: summary.date))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func barColor(for summary: DailyScreenTimeSummary) -> Color {
        let ratio = summary.totalUsed / summary.totalAllocated
        if ratio < 0.7 { return .green }
        if ratio < 1.0 { return .orange }
        return .red
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Fix: use @ObservedObject directly on the singleton so any
// change to appConfigs always triggers a re-render, regardless of
// whether the environment object was injected by the parent.
struct AppUsageBreakdownView: View {
    @ObservedObject private var dataStore = DataStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Configuration")
                .font(.headline)

            let rewardApps = dataStore.appConfigs.filter { $0.configType == .reward && $0.isEnabled }
            let penaltyApps = dataStore.appConfigs.filter { $0.configType == .penalty && $0.isEnabled }

            if rewardApps.isEmpty && penaltyApps.isEmpty {
                Text("No apps configured. Go to Settings to add reward and penalty apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                if !rewardApps.isEmpty {
                    Text("Reward Apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    ForEach(rewardApps) { app in
                        AppBreakdownRow(config: app)
                    }
                }
                if !penaltyApps.isEmpty {
                    Text("Penalty Apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.top, 4)
                    ForEach(penaltyApps) { app in
                        AppBreakdownRow(config: app)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct AppBreakdownRow: View {
    let config: AppConfig

    var body: some View {
        HStack {
            Image(systemName: config.appIcon ?? "app.fill")
                .foregroundColor(config.configType == .reward ? .green : .red)
                .frame(width: 28)
            Text(config.appName)
                .font(.subheadline)
            Spacer()
            Text(config.effectDescription)
                .font(.caption)
                .foregroundColor(config.configType == .reward ? .green : .red)
        }
    }
}

struct AchievementsView: View {
    let achievements: [Achievement]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)

            ForEach(achievements) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !achievement.isUnlocked && achievement.progressTarget > 1 {
                ProgressView(value: achievement.progress)
                    .frame(width: 60)
                    .tint(.blue)
            } else if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
