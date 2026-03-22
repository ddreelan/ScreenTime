import Foundation

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"
    case activity = "activity"
    case screenTime = "screenTime"
    case community = "community"
}

struct Achievement: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var icon: String
    var category: AchievementCategory
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progressCurrent: Double
    var progressTarget: Double

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        progressCurrent: Double = 0,
        progressTarget: Double = 1
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.progressCurrent = progressCurrent
        self.progressTarget = progressTarget
    }

    var progress: Double {
        min(1.0, progressCurrent / progressTarget)
    }

    static var defaultAchievements: [Achievement] {
        [
            Achievement(title: "First Steps", description: "Complete your first activity", icon: "star.fill", category: .activity, progressTarget: 1),
            Achievement(title: "Week Warrior", description: "Stay within your screen time limit for 7 days", icon: "calendar.badge.checkmark", category: .streak, progressTarget: 7),
            Achievement(title: "Activity Champion", description: "Complete 10 activities", icon: "trophy.fill", category: .activity, progressTarget: 10),
            Achievement(title: "Digital Detox", description: "Use less than 1 hour of screen time in a day", icon: "leaf.fill", category: .screenTime, progressTarget: 1),
            Achievement(title: "Early Bird", description: "Start an activity before 8 AM", icon: "sunrise.fill", category: .activity, progressTarget: 1),
            Achievement(title: "Night Owl Redeemed", description: "Complete a meditation after 9 PM", icon: "moon.stars.fill", category: .activity, progressTarget: 1),
        ]
    }
}
