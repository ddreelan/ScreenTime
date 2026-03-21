import Foundation

enum AppConfigType: String, Codable, CaseIterable {
    case reward = "reward"
    case penalty = "penalty"
    case neutral = "neutral"
}

struct AppConfig: Codable, Identifiable {
    var id: UUID
    var bundleIdentifier: String
    var appName: String
    var appIcon: String? // SF Symbol name or asset name
    var configType: AppConfigType
    var minutesPerMinute: Double // Positive = earns time, negative = costs time
    var isEnabled: Bool
    var category: String

    init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        appName: String,
        appIcon: String? = nil,
        configType: AppConfigType = .neutral,
        minutesPerMinute: Double = 0.0,
        isEnabled: Bool = true,
        category: String = "Other"
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.appIcon = appIcon
        self.configType = configType
        self.minutesPerMinute = minutesPerMinute
        self.isEnabled = isEnabled
        self.category = category
    }

    var effectDescription: String {
        switch configType {
        case .reward:
            return "+\(String(format: "%.1f", minutesPerMinute)) min/min"
        case .penalty:
            return "\(String(format: "%.1f", minutesPerMinute)) min/min"
        case .neutral:
            return "No effect"
        }
    }

    static var sampleRewardApps: [AppConfig] {
        [
            AppConfig(bundleIdentifier: "com.apple.Health", appName: "Health", appIcon: "heart.fill", configType: .reward, minutesPerMinute: 2.0, category: "Health"),
            AppConfig(bundleIdentifier: "com.apple.Fitness", appName: "Fitness", appIcon: "figure.walk", configType: .reward, minutesPerMinute: 1.5, category: "Fitness"),
            AppConfig(bundleIdentifier: "com.duolingo.duolingo", appName: "Duolingo", appIcon: "textbook.fill", configType: .reward, minutesPerMinute: 1.0, category: "Education"),
            AppConfig(bundleIdentifier: "com.headspace.headspace", appName: "Headspace", appIcon: "brain.head.profile", configType: .reward, minutesPerMinute: 1.2, category: "Wellness"),
        ]
    }

    static var samplePenaltyApps: [AppConfig] {
        [
            AppConfig(bundleIdentifier: "com.zhiliaoapp.musically", appName: "TikTok", appIcon: "play.rectangle.fill", configType: .penalty, minutesPerMinute: -2.0, category: "Entertainment"),
            AppConfig(bundleIdentifier: "com.instagram.instagram", appName: "Instagram", appIcon: "camera.fill", configType: .penalty, minutesPerMinute: -1.5, category: "Social"),
            AppConfig(bundleIdentifier: "com.atebits.Tweetie2", appName: "Twitter/X", appIcon: "bird.fill", configType: .penalty, minutesPerMinute: -1.0, category: "Social"),
        ]
    }
}
