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
    var timeRewardSeconds: TimeInterval

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        progressCurrent: Double = 0,
        progressTarget: Double = 1,
        timeRewardSeconds: TimeInterval = 0
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
        self.timeRewardSeconds = timeRewardSeconds
    }

    var progress: Double {
        min(1.0, progressCurrent / progressTarget)
    }

    static var defaultAchievements: [Achievement] {
        [
            Achievement(title: "First Steps", description: "Complete your first activity", icon: "star.fill", category: .activity, progressTarget: 1, timeRewardSeconds: 60),
            Achievement(title: "Week Warrior", description: "Stay within your screen time limit for 7 days", icon: "calendar.badge.checkmark", category: .streak, progressTarget: 7, timeRewardSeconds: 300),
            Achievement(title: "Activity Champion", description: "Complete 10 activities", icon: "trophy.fill", category: .activity, progressTarget: 10, timeRewardSeconds: 600),
            Achievement(title: "Digital Detox", description: "Use less than 1 hour of screen time in a day", icon: "leaf.fill", category: .screenTime, progressTarget: 1, timeRewardSeconds: 300),
            Achievement(title: "Early Bird", description: "Start an activity before 8 AM", icon: "sunrise.fill", category: .activity, progressTarget: 1, timeRewardSeconds: 120),
            Achievement(title: "Night Owl Redeemed", description: "Complete a meditation after 9 PM", icon: "moon.stars.fill", category: .activity, progressTarget: 1, timeRewardSeconds: 120),
            Achievement(title: "Marathon Runner", description: "Complete 5 runs", icon: "figure.run", category: .activity, progressTarget: 5, timeRewardSeconds: 300),
            Achievement(title: "Bookworm", description: "Complete 10 reading sessions", icon: "book.fill", category: .activity, progressTarget: 10, timeRewardSeconds: 300),
            Achievement(title: "Zen Master", description: "Complete 10 meditation sessions", icon: "brain.head.profile", category: .activity, progressTarget: 10, timeRewardSeconds: 300),
            Achievement(title: "Fitness Fanatic", description: "Complete 15 exercises", icon: "dumbbell.fill", category: .activity, progressTarget: 15, timeRewardSeconds: 600),
            Achievement(title: "Social Butterfly", description: "Zero penalty app usage for 3 days", icon: "person.2.fill", category: .screenTime, progressTarget: 3, timeRewardSeconds: 300),
            Achievement(title: "Time Banker", description: "Earn 1 hour of screen time total", icon: "banknote.fill", category: .screenTime, progressTarget: 1, timeRewardSeconds: 300),
            Achievement(title: "Consistent", description: "Maintain a 5 day streak", icon: "repeat", category: .streak, progressTarget: 5, timeRewardSeconds: 180),
            Achievement(title: "Power User", description: "Complete 25 activities", icon: "bolt.fill", category: .activity, progressTarget: 25, timeRewardSeconds: 900),
            Achievement(title: "Half Marathon", description: "Use reward apps for 30 minutes total", icon: "timer", category: .screenTime, progressTarget: 1, timeRewardSeconds: 180),
            Achievement(title: "Screen Free Saturday", description: "Use less than 30 minutes on a Saturday", icon: "bed.double.fill", category: .screenTime, progressTarget: 1, timeRewardSeconds: 600),
            Achievement(title: "Mindful Morning", description: "Complete 3 morning activities", icon: "sun.and.horizon.fill", category: .activity, progressTarget: 3, timeRewardSeconds: 180),
            Achievement(title: "Explorer", description: "Try all activity types", icon: "map.fill", category: .activity, progressTarget: 8, timeRewardSeconds: 300),
            Achievement(title: "Overachiever", description: "Earn 2 hours of screen time total", icon: "medal.fill", category: .screenTime, progressTarget: 1, timeRewardSeconds: 600),
            Achievement(title: "Iron Will", description: "Maintain a 10 day streak", icon: "shield.fill", category: .streak, progressTarget: 10, timeRewardSeconds: 900),
            Achievement(title: "Centurion", description: "Complete 100 activities", icon: "crown.fill", category: .activity, progressTarget: 100, timeRewardSeconds: 1800),
            Achievement(title: "App Master", description: "Configure 5 or more apps", icon: "gearshape.2.fill", category: .screenTime, progressTarget: 5, timeRewardSeconds: 120),
            Achievement(title: "Balance Pro", description: "Equal earn and penalty in a day", icon: "scale.3d", category: .screenTime, progressTarget: 1, timeRewardSeconds: 180),
            Achievement(title: "Legendary", description: "Maintain a 30 day streak", icon: "diamond.fill", category: .streak, progressTarget: 30, timeRewardSeconds: 3600),
        ]
    }
}
