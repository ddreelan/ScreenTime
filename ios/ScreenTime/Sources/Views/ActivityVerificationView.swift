import SwiftUI

struct ActivityVerificationView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @State private var showingActivityPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's earned time
                    EarnedTimeBanner(earned: viewModel.todayEarned)
                        .padding(.horizontal)

                    if viewModel.isVerifying, let activity = viewModel.currentActivity {
                        VerificationInProgressView(
                            activity: activity,
                            progress: viewModel.verificationProgress,
                            message: viewModel.verificationMessage,
                            onTap: { viewModel.recordTap() },
                            onComplete: { viewModel.completeManualActivity() },
                            onCancel: { viewModel.cancelActivity() }
                        )
                        .padding(.horizontal)
                    } else {
                        // Activity type grid
                        VStack(alignment: .leading) {
                            Text("Start an Activity")
                                .font(.headline)
                                .padding(.horizontal)
                            ActivityTypeGrid(selectedType: $viewModel.selectedActivityType) { type in
                                viewModel.startActivity(type: type)
                            }
                        }
                    }

                    // Today's activity history
                    if !viewModel.todayActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's History")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(viewModel.todayActivities) { activity in
                                ActivityHistoryRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Activities")
            .overlay {
                if viewModel.showRewardAnimation {
                    RewardAnimationView(earned: viewModel.recentlyEarned)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.showRewardAnimation)
                }
            }
        }
    }
}

struct EarnedTimeBanner: View {
    let earned: TimeInterval

    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            VStack(alignment: .leading) {
                Text("Today's Earned Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("+\(Int(earned / 60)) minutes")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActivityTypeGrid: View {
    @Binding var selectedType: ActivityType
    let onStart: (ActivityType) -> Void

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(ActivityType.allCases, id: \.self) { type in
                ActivityTypeCard(type: type, isSelected: selectedType == type) {
                    selectedType = type
                    onStart(type)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ActivityTypeCard: View {
    let type: ActivityType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                Text("+\(Int(type.rewardMinutes))m")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct VerificationInProgressView: View {
    let activity: Activity
    let progress: Double
    let message: String
    let onTap: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Verifying: \(activity.displayName)")
                .font(.headline)

            Image(systemName: activity.type.icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 8)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if activity.verificationMethod == .tapCount {
                Button(action: onTap) {
                    Text("TAP TO VERIFY")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }

            if activity.verificationMethod == .manual {
                Button(action: onComplete) {
                    Text("COMPLETE ACTIVITY")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }

            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

struct ActivityHistoryRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.type.icon)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Text(activity.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if activity.rewardEarned > 0 {
                        Text("• +\(Int(activity.rewardEarned / 60))m earned")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            Spacer()

            Text(activity.status.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    var statusColor: Color {
        switch activity.status {
        case .verified: return .green
        case .failed: return .red
        case .inProgress: return .blue
        case .cancelled: return .gray
        case .pending: return .orange
        }
    }
}

struct RewardAnimationView: View {
    let earned: TimeInterval

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                Text("🎉 Activity Verified!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("+\(Int(earned / 60)) minutes earned!")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
}
