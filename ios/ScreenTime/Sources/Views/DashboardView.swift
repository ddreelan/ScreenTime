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
