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
    @Published var todayTimeline: [TimelineDataPoint] = []
    @Published var screenTimeEntries: [ScreenTimeEntry] = []

    private let userDefaultsKey = "screentime_userprofile"
    private let appConfigsKey = "screentime_appconfigs"
    private let summaryKey = "screentime_summary"
    private let activitiesKey = "screentime_activities"
    private let achievementsKey = "screentime_achievements"
    private let defaultPenaltyRateKey = "screentime_default_penalty_rate"
    private let timelineKey = "screentime_timeline"
    private let screenTimeEntriesKey = "screentime_entries"

    var defaultPenaltyRate: Double {
        get {
            let val = UserDefaults.standard.object(forKey: defaultPenaltyRateKey) as? Double
            return val ?? -1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultPenaltyRateKey)
        }
    }

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

        // Load today's timeline
        loadTimeline()
        loadScreenTimeEntries()

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
            let penalty = duration * abs(config.minutesPerMinute) / 60.0
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
            if updatedAchievements[i].isUnlocked { continue }

            switch updatedAchievements[i].title {
            case "First Steps":
                updatedAchievements[i].progressCurrent = min(1, Double(completedActivities.count))
                if completedActivities.count >= 1 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Week Warrior":
                let streak = calculateStreak()
                updatedAchievements[i].progressCurrent = Double(streak)
                if streak >= 7 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Activity Champion":
                updatedAchievements[i].progressCurrent = Double(completedActivities.count)
                if completedActivities.count >= 10 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Digital Detox":
                if todaySummary.totalUsed < 3600 && todaySummary.totalUsed > 0 {
                    updatedAchievements[i].progressCurrent = 1
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Early Bird":
                let hasEarly = completedActivities.contains { Calendar.current.component(.hour, from: $0.startTime) < 8 }
                if hasEarly {
                    updatedAchievements[i].progressCurrent = 1
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Night Owl Redeemed":
                let hasNight = completedActivities.contains {
                    $0.type == .meditation && Calendar.current.component(.hour, from: $0.startTime) >= 21
                }
                if hasNight {
                    updatedAchievements[i].progressCurrent = 1
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Marathon Runner":
                let runCount = completedActivities.filter { $0.type == .running }.count
                updatedAchievements[i].progressCurrent = Double(runCount)
                if runCount >= 5 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Bookworm":
                let readCount = completedActivities.filter { $0.type == .reading }.count
                updatedAchievements[i].progressCurrent = Double(readCount)
                if readCount >= 10 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Zen Master":
                let meditateCount = completedActivities.filter { $0.type == .meditation }.count
                updatedAchievements[i].progressCurrent = Double(meditateCount)
                if meditateCount >= 10 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Fitness Fanatic":
                let exerciseCount = completedActivities.filter { $0.type == .exercise }.count
                updatedAchievements[i].progressCurrent = Double(exerciseCount)
                if exerciseCount >= 15 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Social Butterfly":
                let zeroPenaltyDays = weeklyHistory.filter { $0.totalPenalty == 0 }.count
                updatedAchievements[i].progressCurrent = Double(zeroPenaltyDays)
                if zeroPenaltyDays >= 3 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Time Banker":
                let totalEarned = weeklyHistory.reduce(0) { $0 + $1.totalEarned }
                updatedAchievements[i].progressCurrent = min(1, totalEarned / 3600)
                if totalEarned >= 3600 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Consistent":
                let streak = calculateStreak()
                updatedAchievements[i].progressCurrent = Double(streak)
                if streak >= 5 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Power User":
                updatedAchievements[i].progressCurrent = Double(completedActivities.count)
                if completedActivities.count >= 25 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Half Marathon":
                let totalEarned = weeklyHistory.reduce(0) { $0 + $1.totalEarned }
                updatedAchievements[i].progressCurrent = min(1, totalEarned / 1800)
                if totalEarned >= 1800 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Screen Free Saturday":
                let saturdaySummary = weeklyHistory.first {
                    Calendar.current.component(.weekday, from: $0.date) == 7 // Saturday
                }
                if let sat = saturdaySummary, sat.totalUsed < 1800 {
                    updatedAchievements[i].progressCurrent = 1
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Mindful Morning":
                let morningCount = completedActivities.filter {
                    Calendar.current.component(.hour, from: $0.startTime) < 8
                }.count
                updatedAchievements[i].progressCurrent = Double(morningCount)
                if morningCount >= 3 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Explorer":
                let typesUsed = Set(completedActivities.map { $0.type })
                updatedAchievements[i].progressCurrent = Double(typesUsed.count)
                updatedAchievements[i].progressTarget = Double(ActivityType.allCases.count)
                if typesUsed.count >= ActivityType.allCases.count {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Overachiever":
                let totalEarned = weeklyHistory.reduce(0) { $0 + $1.totalEarned }
                updatedAchievements[i].progressCurrent = min(1, totalEarned / 7200)
                if totalEarned >= 7200 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Iron Will":
                let streak = calculateStreak()
                updatedAchievements[i].progressCurrent = Double(streak)
                if streak >= 10 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Centurion":
                updatedAchievements[i].progressCurrent = Double(completedActivities.count)
                if completedActivities.count >= 100 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "App Master":
                updatedAchievements[i].progressCurrent = Double(appConfigs.count)
                if appConfigs.count >= 5 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            case "Balance Pro":
                if todaySummary.totalEarned > 0 && todaySummary.totalPenalty > 0 {
                    let ratio = todaySummary.totalEarned / todaySummary.totalPenalty
                    if ratio >= 0.8 && ratio <= 1.2 {
                        updatedAchievements[i].progressCurrent = 1
                        updatedAchievements[i].isUnlocked = true
                        updatedAchievements[i].unlockedAt = Date()
                    }
                }

            case "Legendary":
                let streak = calculateStreak()
                updatedAchievements[i].progressCurrent = Double(streak)
                if streak >= 30 {
                    updatedAchievements[i].isUnlocked = true
                    updatedAchievements[i].unlockedAt = Date()
                }

            default:
                break
            }

            // Grant time reward when newly unlocked
            if updatedAchievements[i].isUnlocked && updatedAchievements[i].timeRewardSeconds > 0 {
                todaySummary.totalEarned += updatedAchievements[i].timeRewardSeconds
            }
        }

        achievements = updatedAchievements
        saveObject(achievements, forKey: achievementsKey)
    }

    private func calculateStreak() -> Int {
        let sorted = weeklyHistory.sorted { $0.date > $1.date }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        for summary in sorted {
            let summaryDate = Calendar.current.startOfDay(for: summary.date)
            if summaryDate == checkDate && summary.remaining > 0 {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Screen Time Entries

    func saveScreenTimeEntry(_ entry: ScreenTimeEntry) {
        let today = Calendar.current.startOfDay(for: Date())
        guard Calendar.current.isDate(entry.date, inSameDayAs: today) else { return }
        screenTimeEntries.append(entry)
        saveObject(screenTimeEntries, forKey: screenTimeEntriesKey)
    }

    private func loadScreenTimeEntries() {
        let today = Calendar.current.startOfDay(for: Date())
        if let entries: [ScreenTimeEntry] = loadObject(forKey: screenTimeEntriesKey) {
            screenTimeEntries = entries.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        } else {
            screenTimeEntries = []
        }
    }

    // MARK: - Timeline

    func addTimelineDataPoint(_ point: TimelineDataPoint) {
        todayTimeline.append(point)
        saveTimeline()
    }

    func loadTimeline() {
        let today = Calendar.current.startOfDay(for: Date())
        if let points: [TimelineDataPoint] = loadObject(forKey: timelineKey) {
            todayTimeline = points.filter { $0.timestamp >= today }
        } else {
            todayTimeline = []
        }
    }

    private func saveTimeline() {
        // Keep only today's points
        let today = Calendar.current.startOfDay(for: Date())
        todayTimeline = todayTimeline.filter { $0.timestamp >= today }
        saveObject(todayTimeline, forKey: timelineKey)
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
