import SwiftUI

struct ActivityVerificationView: View {
    @StateObject private var viewModel = ActivityViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Today's earned time summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Earned Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(formatTime(viewModel.todayEarned))
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // Activity type picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start an Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ActivityType.allCases, id: \.self) { type in
                                    ActivityTypeButton(
                                        type: type,
                                        isSelected: viewModel.selectedActivityType == type
                                    ) {
                                        viewModel.selectedActivityType = type
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button {
                            viewModel.startActivity(type: viewModel.selectedActivityType)
                        } label: {
                            Label("Start \(viewModel.selectedActivityType.displayName)", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal)
                        .disabled(viewModel.currentActivity != nil)
                    }

                    // Active verification session
                    if viewModel.currentActivity != nil {
                        ActiveVerificationCard(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    // Reward animation
                    if viewModel.showRewardAnimation {
                        RewardBannerView(earned: viewModel.recentlyEarned)
                            .padding(.horizontal)
                    }

                    // Today's activity history
                    if !viewModel.todayActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today's History")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.todayActivities) { activity in
                                ActivityHistoryRow(activity: activity)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        if hours > 0 { return "\(hours)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
}

// MARK: - Activity Type Button

struct ActivityTypeButton: View {
    let type: ActivityType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.green : Color.green.opacity(0.12))
                    .cornerRadius(12)
                Text(type.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
    }
}

// MARK: - Active Verification Card

struct ActiveVerificationCard: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                if let activity = viewModel.currentActivity {
                    Image(systemName: activity.type.icon)
                        .font(.title2)
                        .foregroundColor(.green)
                    Text(activity.displayName)
                        .font(.headline)
                }
                Spacer()
                Button(role: .destructive) {
                    viewModel.cancelActivity()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.subheadline)
                }
            }

            ProgressView(value: viewModel.verificationProgress)
                .tint(.green)

            Text(viewModel.verificationMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let activity = viewModel.currentActivity,
               activity.verificationMethod == .tapCount {
                Button {
                    viewModel.recordTap()
                } label: {
                    Text("Tap to verify")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }

            if let activity = viewModel.currentActivity,
               activity.verificationMethod == .manual {
                Button {
                    viewModel.completeManualActivity()
                } label: {
                    Text("Mark as Complete")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Reward Banner

struct RewardBannerView: View {
    let earned: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity Complete! 🎉")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("+\(Int(earned / 60)) minutes earned")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.12))
        .cornerRadius(14)
    }
}

// MARK: - Activity History Row

struct ActivityHistoryRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 36, height: 36)
                .background(statusColor.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(activity.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            Spacer()

            if activity.rewardEarned > 0 {
                Text("+\(Int(activity.rewardEarned / 60))m")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
    }

    private var statusColor: Color {
        switch activity.status {
        case .verified: return .green
        case .failed, .cancelled: return .red
        case .inProgress: return .blue
        case .pending: return .orange
        }
    }
}
