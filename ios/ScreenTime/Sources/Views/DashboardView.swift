import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var screenTimeService: ScreenTimeService

    @State private var activeQuickStart: ActivityType? = nil
    @State private var quickStartElapsed: TimeInterval = 0
    @State private var quickStartTimer: Timer? = nil
    @State private var showingQuickStartSheet = false

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
                    QuickActionsView(onQuickStart: { activityType in
                        activeQuickStart = activityType
                        quickStartElapsed = 0
                        quickStartTimer?.invalidate()
                        quickStartTimer = nil
                        showingQuickStartSheet = true
                    })
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
            .sheet(isPresented: $showingQuickStartSheet, onDismiss: {
                quickStartTimer?.invalidate()
                quickStartTimer = nil
            }) {
                if let activityType = activeQuickStart {
                    QuickStartTimerSheet(
                        activityType: activityType,
                        elapsed: $quickStartElapsed,
                        timer: $quickStartTimer,
                        onStopAndSave: { elapsed in
                            let reward = ActivityVerificationService.shared.calculateReward(for: activityType, duration: elapsed)
                            let activity = Activity(
                                type: activityType,
                                startTime: Date().addingTimeInterval(-elapsed),
                                endTime: Date(),
                                duration: elapsed,
                                verificationMethod: .manual,
                                status: .verified,
                                rewardEarned: reward
                            )
                            DataStore.shared.addActivity(activity)
                            screenTimeService.addEarnedTime(reward)
                            showingQuickStartSheet = false
                        },
                        onDismiss: {
                            showingQuickStartSheet = false
                        }
                    )
                }
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
    let onQuickStart: (ActivityType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(icon: "figure.walk", title: "Walk", color: .green) { onQuickStart(.walking) }
                QuickActionButton(icon: "book.fill", title: "Read", color: .blue) { onQuickStart(.reading) }
                QuickActionButton(icon: "brain.head.profile", title: "Meditate", color: .purple) { onQuickStart(.meditation) }
                QuickActionButton(icon: "figure.run", title: "Run", color: .orange) { onQuickStart(.running) }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
        .buttonStyle(.plain)
    }
}

struct QuickStartTimerSheet: View {
    let activityType: ActivityType
    @Binding var elapsed: TimeInterval
    @Binding var timer: Timer?
    let onStopAndSave: (TimeInterval) -> Void
    let onDismiss: () -> Void

    @State private var isRunning = false

    private var elapsedFormatted: String {
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var estimatedReward: Double {
        let reward = ActivityVerificationService.shared.calculateReward(for: activityType, duration: elapsed)
        return reward / 60.0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: activityType.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(activityType.displayName)
                    .font(.title)
                    .fontWeight(.bold)

                Text(elapsedFormatted)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))

                Text("Earning: +\(String(format: "%.1f", estimatedReward))m")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                if !isRunning {
                    Button(action: startTimer) {
                        Text("Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                    }
                } else {
                    Button(action: { onStopAndSave(elapsed) }) {
                        Text("Stop & Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                }
            }
            .padding(24)
            .navigationTitle("Quick Start")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { onDismiss() })
        }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }
}
