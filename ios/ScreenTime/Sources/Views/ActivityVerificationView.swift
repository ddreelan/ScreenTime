import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var screenTimeService: ScreenTimeService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Ring
                    TimeRingView(
                        progress: viewModel.progressValue,
                        remaining: viewModel.remainingTimeFormatted,
                        color: viewModel.progressColor
                    )
                    .frame(height: 220)
                    .padding(.top)

                    // Stats Row
                    HStack(spacing: 16) {
                        StatCard(title: "Used", value: viewModel.usedTimeFormatted, icon: "clock.fill", color: .orange)
                        StatCard(title: "Earned", value: viewModel.earnedTimeFormatted, icon: "plus.circle.fill", color: .green)
                        StatCard(title: "Allocated", value: formatTime(viewModel.todaySummary.totalAllocated), icon: "timer", color: .blue)
                    }
                    .padding(.horizontal)

                    // Motivational message
                    Text(viewModel.motivationalMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Active App Tracker
                    ActiveAppTrackerView()
                        .padding(.horizontal)

                    // Recent Activities
                    if !viewModel.recentActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Activities")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.recentActivities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }

                    // Quick Actions
                    QuickActionsView()
                        .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Active App Tracker

struct ActiveAppTrackerView: View {
    @ObservedObject private var screenTimeService = ScreenTimeService.shared
    @ObservedObject private var dataStore = DataStore.shared

    private var rewardApps: [AppConfig] {
        dataStore.appConfigs.filter { $0.configType == .reward && $0.isEnabled }
    }

    private var penaltyApps: [AppConfig] {
        dataStore.appConfigs.filter { $0.configType == .penalty && $0.isEnabled }
    }

    private var activeConfig: AppConfig? {
        guard let id = screenTimeService.activeAppBundleID else { return nil }
        return dataStore.appConfigs.first { $0.bundleIdentifier == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Using")
                .font(.headline)

            if let active = activeConfig {
                // Active app banner
                HStack(spacing: 12) {
                    Image(systemName: active.appIcon ?? "app.fill")
                        .font(.title2)
                        .foregroundColor(active.configType == .reward ? .green : .red)
                        .frame(width: 40, height: 40)
                        .background((active.configType == .reward ? Color.green : Color.red).opacity(0.15))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(active.appName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(active.configType == .reward ? "Earning time ✦" : "Costing time ✦")
                            .font(.caption)
                            .foregroundColor(active.configType == .reward ? .green : .red)
                    }

                    Spacer()

                    Button("Stop") {
                        screenTimeService.setActiveApp(bundleID: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

            } else {
                // App picker
                if rewardApps.isEmpty && penaltyApps.isEmpty {
                    Text("Add reward or penalty apps in Settings to start tracking.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(rewardApps + penaltyApps) { config in
                                Button {
                                    screenTimeService.setActiveApp(bundleID: config.bundleIdentifier)
                                    if !screenTimeService.isTracking {
                                        screenTimeService.startTracking()
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: config.appIcon ?? "app.fill")
                                            .font(.title2)
                                            .foregroundColor(config.configType == .reward ? .green : .red)
                                            .frame(width: 48, height: 48)
                                            .background((config.configType == .reward ? Color.green : Color.red).opacity(0.12))
                                            .cornerRadius(12)
                                        Text(config.appName)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 64)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Text("Tap an app above when you start using it")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Existing subviews (unchanged)

struct TimeRingView: View {
    let progress: Double
    let remaining: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                .padding(20)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
                .padding(20)

            VStack(spacing: 4) {
                Text(remaining)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text("remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title2)
                .foregroundColor(activity.status == .verified ? .green : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if activity.rewardEarned > 0 {
                    Text("+\(Int(activity.rewardEarned / 60)) min earned")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Text(activity.status.rawValue.capitalized)
                .font(.caption)
                .padding(4)
                .background(activity.status == .verified ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                .foregroundColor(activity.status == .verified ? .green : .gray)
                .cornerRadius(6)
        }
        .padding(.horizontal)
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(icon: "figure.walk", title: "Walk", color: .green)
                QuickActionButton(icon: "book.fill", title: "Read", color: .blue)
                QuickActionButton(icon: "brain.head.profile", title: "Meditate", color: .purple)
                QuickActionButton(icon: "figure.run", title: "Run", color: .orange)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
