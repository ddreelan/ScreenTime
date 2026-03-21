import Foundation
import Combine

class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var userProfile: UserProfile?
    @Published var appConfigs: [AppConfig] = []
    @Published var todaySummary: DailyScreenTimeSummary
    @Published var weeklyHistory: [DailyScreenTimeSummary] = []
    @Published var activities: [Activity] = []
    @Published var achievements: [Achievement] = []

    private let userDefaultsKey = "screentime_userprofile"
    private let appConfigsKey = "screentime_appconfigs"
    private let summaryKey = "screentime_summary"
    private let activitiesKey = "screentime_activities"
    private let achievementsKey = "screentime_achievements"

    private init() {
        self.todaySummary = DailyScreenTimeSummary()
        loadData()
        loadDefaultAppsIfNeeded()
    }

    func loadData() {
        userProfile = loadObject(forKey: userDefaultsKey)
        appConfigs = loadObject(forKey: appConfigsKey) ?? []
        activities = loadObject(forKey: activitiesKey) ?? []
        achievements = loadObject(forKey: achievementsKey) ?? Achievement.defaultAchievements

        // Load today's summary
        let today = Calendar.current.startOfDay(for: Date())
        if let summaries: [DailyScreenTimeSummary] = loadObject(forKey: summaryKey) {
            weeklyHistory = summaries
            if let todayEntry = summaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                todaySummary = todayEntry
            } else {
                todaySummary = DailyScreenTimeSummary(
                    date: today,
                    totalAllocated: userProfile?.dailyScreenTimeLimit ?? 2 * 3600
                )
            }
        }
    }

    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveObject(profile, forKey: userDefaultsKey)
    }

    func saveAppConfigs(_ configs: [AppConfig]) {
        appConfigs = configs
        saveObject(configs, forKey: appConfigsKey)
    }

    func addAppConfig(_ config: AppConfig) {
        var configs = appConfigs
        configs.append(config)
        saveAppConfigs(configs)
    }

    func updateAppConfig(_ config: AppConfig) {
        var configs = appConfigs
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        }
        saveAppConfigs(configs)
    }

    func removeAppConfig(_ id: UUID) {
        let configs = appConfigs.filter { $0.id != id }
        saveAppConfigs(configs)
    }

    func addActivity(_ activity: Activity) {
        activities.append(activity)
        saveObject(activities, forKey: activitiesKey)
        if activity.status == .verified {
            todaySummary.totalEarned += activity.rewardEarned
            saveSummary()
        }
        checkAchievements()
    }

    func updateActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            let oldActivity = activities[index]
            activities[index] = activity
            saveObject(activities, forKey: activitiesKey)
            if activity.status == .verified && oldActivity.status != .verified {
                todaySummary.totalEarned += activity.rewardEarned
                saveSummary()
            }
        }
        checkAchievements()
    }

    func recordScreenTime(duration: TimeInterval, for appConfig: AppConfig?) {
        todaySummary.totalUsed += duration
        if let config = appConfig, config.configType == .penalty {
            let penalty = duration * abs(config.minutesPerMinute) * 60
            todaySummary.totalPenalty += penalty
        }
        saveSummary()
    }

    func saveSummary() {
        var summaries = weeklyHistory
        let today = Calendar.current.startOfDay(for: Date())
        if let index = summaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            summaries[index] = todaySummary
        } else {
            summaries.append(todaySummary)
        }
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        summaries = summaries.filter { $0.date >= thirtyDaysAgo }
        weeklyHistory = summaries
        saveObject(summaries, forKey: summaryKey)
    }

    private func loadDefaultAppsIfNeeded() {
        if appConfigs.isEmpty {
            var defaultConfigs: [AppConfig] = []
            defaultConfigs.append(contentsOf: AppConfig.sampleRewardApps)
            defaultConfigs.append(contentsOf: AppConfig.samplePenaltyApps)
            saveAppConfigs(defaultConfigs)
        }
    }

    private func checkAchievements() {
        let completedActivities = activities.filter { $0.status == .verified }
        var updatedAchievements = achievements

        for i in 0..<updatedAchievements.count {
            switch updatedAchievements[i].title {
            case "First Steps":
                if completedActivities.count >= 1 && !updatedAchievements[i].isUnlocked {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                    updatedAchievements[i].progressCurrent = 1
                }
            case "Activity Champion":
                updatedAchievements[i].progressCurrent = Double(completedActivities.count)
                if completedActivities.count >= 10 && !updatedAchievements[i].isUnlocked {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }
            default:
                break
            }
        }

        achievements = updatedAchievements
        saveObject(achievements, forKey: achievementsKey)
    }

    // MARK: - Generic persistence helpers
    private func saveObject<T: Encodable>(_ object: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(object) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadObject<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
