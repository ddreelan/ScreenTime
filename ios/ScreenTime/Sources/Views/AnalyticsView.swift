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

                    // Daily timeline chart
                    DailyTimelineChartView(dataPoints: dataStore.todayTimeline)
                        .frame(height: 300)
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
                    HStack {
                        Text("Total Reward Apps: \(rewardApps.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Spacer()
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
                    HStack {
                        Text("Total Penalty Apps: \(penaltyApps.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
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

// MARK: - Daily Timeline Chart (7B + 7C)

struct DailyTimelineChartView: View {
    let dataPoints: [TimelineDataPoint]
    @State private var selectedIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Timeline")
                .font(.headline)

            if dataPoints.isEmpty {
                Text("No timeline data yet. Data is recorded every 30 seconds while tracking.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                ZStack(alignment: .topLeading) {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height: CGFloat = 180

                        // Y-axis range
                        let maxMinutes = (dataPoints.map { $0.remainingSeconds }.max() ?? 3600) / 60.0
                        let yMax = max(maxMinutes * 1.1, 1)

                        // Draw the line chart
                        Path { path in
                            for (index, point) in dataPoints.enumerated() {
                                let x = dataPoints.count > 1
                                    ? width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                    : width / 2
                                let y = height - CGFloat(point.remainingSeconds / 60.0 / yMax) * height
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)

                        // Color-coded segments
                        ForEach(0..<max(0, dataPoints.count - 1), id: \.self) { index in
                            let x1 = width * CGFloat(index) / CGFloat(max(1, dataPoints.count - 1))
                            let x2 = width * CGFloat(index + 1) / CGFloat(max(1, dataPoints.count - 1))
                            let y1 = height - CGFloat(dataPoints[index].remainingSeconds / 60.0 / yMax) * height
                            let y2 = height - CGFloat(dataPoints[index + 1].remainingSeconds / 60.0 / yMax) * height

                            let segmentColor: Color = {
                                if dataPoints[index + 1].delta > 0 { return .green }
                                if dataPoints[index + 1].delta < 0 { return .red }
                                return Color.gray
                            }()

                            Path { path in
                                path.move(to: CGPoint(x: x1, y: y1))
                                path.addLine(to: CGPoint(x: x2, y: y2))
                            }
                            .stroke(segmentColor, lineWidth: 2.5)
                        }

                        // Selected point indicator
                        if let idx = selectedIndex, idx < dataPoints.count {
                            let x = dataPoints.count > 1
                                ? width * CGFloat(idx) / CGFloat(dataPoints.count - 1)
                                : width / 2
                            let y = height - CGFloat(dataPoints[idx].remainingSeconds / 60.0 / yMax) * height
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }

                        // Drag gesture for interactivity (7C)
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard !dataPoints.isEmpty else { return }
                                        let fraction = value.location.x / width
                                        let idx = Int(round(fraction * CGFloat(dataPoints.count - 1)))
                                        selectedIndex = max(0, min(dataPoints.count - 1, idx))
                                    }
                                    .onEnded { _ in
                                        selectedIndex = nil
                                    }
                            )
                    }
                    .frame(height: 180)

                    // Tooltip overlay
                    if let idx = selectedIndex, idx < dataPoints.count {
                        let point = dataPoints[idx]
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeLabel(for: point.timestamp))
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Text("\(Int(point.remainingSeconds / 60))m remaining")
                                .font(.caption2)
                            if let app = point.activeAppName {
                                Text(app)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(6)
                        .background(Color(.systemBackground).opacity(0.95))
                        .cornerRadius(6)
                        .shadow(radius: 2)
                    }
                }

                // X-axis labels
                HStack {
                    if let first = dataPoints.first {
                        Text(timeLabel(for: first.timestamp))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let last = dataPoints.last {
                        Text(timeLabel(for: last.timestamp))
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

    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct AchievementsView: View {
    let achievements: [Achievement]
    @State private var isExpanded = false

    /// Returns the top 5 locked achievements nearest to completion, followed by unlocked ones.
    private var topAchievements: [Achievement] {
        let locked = achievements
            .filter { !$0.isUnlocked }
            .sorted { $0.progress > $1.progress }
        return Array(locked.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                ForEach(achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            } else {
                ForEach(topAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
                if achievements.contains(where: { $0.isUnlocked }) || achievements.filter({ !$0.isUnlocked }).count > 5 {
                    Button(action: { withAnimation { isExpanded = true } }) {
                        Text("Show All Achievements")
                            .font(.caption)
                            .foregroundColor(.blue)
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

struct AchievementRow: View {
    let achievement: Achievement

    private var rewardLabel: String {
        let seconds = Int(achievement.timeRewardSeconds.rounded())
        if seconds >= 3600 {
            let hours = seconds / 3600
            let mins = (seconds % 3600) / 60
            return mins > 0 ? "+\(hours)h \(mins)m" : "+\(hours)h"
        } else {
            return "+\(seconds / 60)m"
        }
    }

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

            VStack(alignment: .trailing, spacing: 4) {
                Text(rewardLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .green : .orange)

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
}
