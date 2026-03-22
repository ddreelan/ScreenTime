import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var isEditing = false
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGoals: Set<String> = []

    let availableGoals = [
        "Reduce social media usage",
        "Spend more time outdoors",
        "Read more books",
        "Exercise regularly",
        "Better work-life balance",
        "Improve sleep habits",
        "Spend quality time with family",
        "Learn new skills"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Text(nameInitials)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        if isEditing {
                            VStack(spacing: 8) {
                                TextField("Your Name", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                TextField("Age", text: $age)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.horizontal, 40)
                        } else {
                            Text(dataStore.userProfile?.name ?? "Set up your profile")
                                .font(.title2)
                                .fontWeight(.bold)
                            if let age = dataStore.userProfile?.age {
                                Text("Age \(age)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()

                    // Goals Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Goals")
                            .font(.headline)
                            .padding(.horizontal)

                        if isEditing {
                            VStack(spacing: 8) {
                                ForEach(availableGoals, id: \.self) { goal in
                                    GoalToggleRow(goal: goal, isSelected: selectedGoals.contains(goal)) {
                                        if selectedGoals.contains(goal) {
                                            selectedGoals.remove(goal)
                                        } else {
                                            selectedGoals.insert(goal)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            let goals = dataStore.userProfile?.goals ?? []
                            if goals.isEmpty {
                                Text("No goals set. Tap Edit to add goals.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(goals, id: \.self) { goal in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(goal)
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lifetime Statistics")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            ProfileStatCard(
                                title: "Activities",
                                value: "\(dataStore.activities.filter { $0.status == .verified }.count)",
                                icon: "figure.walk",
                                color: .blue
                            )
                            ProfileStatCard(
                                title: "Days Tracked",
                                value: "\(dataStore.weeklyHistory.count)",
                                icon: "calendar",
                                color: .purple
                            )
                            ProfileStatCard(
                                title: "Time Earned",
                                value: formatTime(totalEarned),
                                icon: "plus.circle.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    saveProfile()
                } else {
                    name = dataStore.userProfile?.name ?? ""
                    age = dataStore.userProfile?.age.flatMap { $0 > 0 ? "\($0)" : nil } ?? ""
                    selectedGoals = Set(dataStore.userProfile?.goals ?? [])
                }
                isEditing.toggle()
            })
        }
    }

    private var nameInitials: String {
        let profileName = dataStore.userProfile?.name ?? "U"
        let components = profileName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2).map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }

    private var totalEarned: TimeInterval {
        dataStore.activities
            .filter { $0.status == .verified }
            .reduce(0) { $0 + $1.rewardEarned }
    }

    private func saveProfile() {
        let profile = UserProfile(
            id: dataStore.userProfile?.id ?? UUID(),
            name: name.isEmpty ? "User" : name,
            age: Int(age) ?? 0,
            dailyScreenTimeLimit: dataStore.userProfile?.dailyScreenTimeLimit ?? 2 * 3600,
            goals: Array(selectedGoals),
            updatedAt: Date()
        )
        dataStore.saveUserProfile(profile)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}

struct GoalToggleRow: View {
    let goal: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                Text(goal)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}
