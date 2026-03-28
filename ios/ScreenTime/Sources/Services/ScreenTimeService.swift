import Foundation
import Combine

class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published var isTracking = false
    @Published var currentAppTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0

    /// Set this to the bundle ID of the app currently being used.
    /// Set to nil when no specific app is active.
    var activeAppBundleID: String? = nil

    private var trackingTimer: Timer?
    private var dataStore: DataStore { DataStore.shared }
    private var cancellables = Set<AnyCancellable>()

    /// Tracks how many seconds have elapsed for the current active app session,
    /// used to calculate total earned/cost for the periodic update notification.
    private var activeAppSessionSeconds: TimeInterval = 0

    /// How often (in seconds) to send a running update notification while an app is active.
    private let updateNotificationInterval: TimeInterval = 300 // 5 minutes

    private init() {
        updateRemainingTime()
    }

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
    }

    func stopTracking() {
        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil
    }

    /// Call this when the user declares they are starting or stopping a specific app.
    func setActiveApp(bundleID: String?) {
        activeAppBundleID = bundleID
        activeAppSessionSeconds = 0

        // Send an immediate notification when a reward/penalty app is started
        if let id = bundleID,
           let config = dataStore.appConfigs.first(where: { $0.bundleIdentifier == id && $0.isEnabled }),
           config.configType != .neutral {
            NotificationService.shared.sendAppStartedNotification(
                appName: config.appName,
                configType: config.configType,
                ratePerMinute: config.minutesPerMinute,
                remainingSeconds: remainingTime
            )
        }
    }

    private func tick() {
        currentAppTime += 1

        // Look up the active app config (if any)
        let activeConfig = activeAppBundleID.flatMap { id in
            dataStore.appConfigs.first { $0.bundleIdentifier == id && $0.isEnabled }
        }

        // Always add 1 second of base usage
        dataStore.todaySummary.totalUsed += 1

        // Self-app exemption: skip all reward/penalty logic for ScreenTime itself
        if activeAppBundleID == Bundle.main.bundleIdentifier {
            dataStore.saveSummary()
            updateRemainingTime()
            return
        }

        // Apply reward or penalty multiplier based on the active app config
        if let config = activeConfig {
            switch config.configType {
            case .reward:
                let rewardPerSecond = config.minutesPerMinute / 60.0
                dataStore.todaySummary.totalEarned += rewardPerSecond
                activeAppSessionSeconds += rewardPerSecond
            case .penalty:
                let penaltyPerSecond = abs(config.minutesPerMinute) / 60.0
                dataStore.todaySummary.totalPenalty += penaltyPerSecond
                activeAppSessionSeconds += penaltyPerSecond
            case .neutral:
                break
            }

            // Send a running update every 5 minutes while the app is active
            if config.configType != .neutral,
               activeAppSessionSeconds > 0,
               currentAppTime.truncatingRemainder(dividingBy: updateNotificationInterval) == 0 {
                NotificationService.shared.sendAppUpdateNotification(
                    appName: config.appName,
                    configType: config.configType,
                    earnedOrCostSeconds: activeAppSessionSeconds,
                    remainingSeconds: remainingTime
                )
            }
        } else if activeAppBundleID != nil {
            // Default penalty for unconfigured apps
            let penaltyPerSecond = abs(dataStore.defaultPenaltyRate) / 60.0
            dataStore.todaySummary.totalPenalty += penaltyPerSecond
        }

        dataStore.saveSummary()
        updateRemainingTime()

        if remainingTime <= 0 {
            NotificationService.shared.sendLimitReachedNotification()
        } else if remainingTime == 300 { // 5 minutes warning
            NotificationService.shared.sendFiveMinuteWarning()
        }
    }

    func updateRemainingTime() {
        let summary = dataStore.todaySummary
        remainingTime = summary.remaining
    }

    func addEarnedTime(_ seconds: TimeInterval) {
        dataStore.todaySummary.totalEarned += seconds
        dataStore.saveSummary()
        updateRemainingTime()
    }

    func recordUsage(duration: TimeInterval, appName: String, bundleID: String) {
        let appConfig = dataStore.appConfigs.first { $0.bundleIdentifier == bundleID }
        dataStore.recordScreenTime(duration: duration, for: appConfig)
        updateRemainingTime()
    }

    var formattedRemainingTime: String {
        formatTime(remainingTime)
    }

    var formattedUsedTime: String {
        formatTime(dataStore.todaySummary.totalUsed)
    }

    var formattedAllocatedTime: String {
        formatTime(dataStore.todaySummary.totalAllocated)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
