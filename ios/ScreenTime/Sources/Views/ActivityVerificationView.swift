import SwiftUI

struct ActivityVerificationView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.pendingActivities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Verify Activities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .onAppear { viewModel.refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("All caught up!")
                .font(.title2)
                .fontWeight(.semibold)
            Text("No activities pending verification.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activityList: some View {
        List(viewModel.pendingActivities) { activity in
            ActivityVerificationRow(activity: activity) { verified in
                viewModel.verify(activity: activity, approved: verified)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ActivityVerificationRow: View {
    let activity: Activity
    let onVerify: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: activity.type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(activity.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("+\(Int(activity.rewardEarned / 60)) min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            if let notes = activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 48)
            }

            HStack(spacing: 12) {
                Button {
                    onVerify(false)
                } label: {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    onVerify(true)
                } label: {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }
}
