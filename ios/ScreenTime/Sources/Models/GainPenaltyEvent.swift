import Foundation

enum GainPenaltyType: String, Codable {
    case rewardApp = "reward_app"
    case penaltyApp = "penalty_app"
    case activityReward = "activity_reward"
    case achievementBonus = "achievement_bonus"
}

struct GainPenaltyEvent: Codable, Identifiable {
    var id: String
    var type: GainPenaltyType
    var appName: String?
    var activityName: String?
    var achievementTitle: String?
    var secondsDelta: Int
    var timestamp: Date
    var icon: String

    var isGain: Bool { secondsDelta > 0 }

    var sourceLabel: String {
        activityName ?? appName ?? achievementTitle ?? "Unknown"
    }

    init(
        id: String = UUID().uuidString,
        type: GainPenaltyType,
        appName: String? = nil,
        activityName: String? = nil,
        achievementTitle: String? = nil,
        secondsDelta: Int,
        timestamp: Date = Date(),
        icon: String
    ) {
        self.id = id
        self.type = type
        self.appName = appName
        self.activityName = activityName
        self.achievementTitle = achievementTitle
        self.secondsDelta = secondsDelta
        self.timestamp = timestamp
        self.icon = icon
    }
}
