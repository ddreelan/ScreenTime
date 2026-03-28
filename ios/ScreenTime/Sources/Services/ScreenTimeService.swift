import Foundation
import Combine

class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published var isTracking = false
    @Published var currentAppTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0

    /// Set this to the bundle ID of the app currently being used
    /// (e.g. "com.instagram.instagram") to apply reward/penalty multipliers.
    /// Set to nil when no specific app is active.
    var activeAppBundleID: String? = nil

    private var trackingTimer: Timer?
    private var dataStore: DataStore { DataStore.shared }
    private var cancellables = Set<AnyCancellable>()

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

    /// Call this when the user starts using a specific app.
    func setActiveApp(bundleID: String?) {
        activeAppBundleID = bundleID
    }

    private func tick() {
        currentAppTime += 1

        // Look up the active app config (if any)
        let activeConfig = activeAppBundleID.flatMap { id in
            dataStore.appConfigs.first { $0.bundleIdentifier == id && $0.isEnabled }
        }

        // Always add 1 second of base usage
        dataStore.todaySummary.totalUsed += 1

        // Apply penalty multiplier if the active app is a penalty app.
        // e.g. minutesPerMinute = -1.5 means 1 second of use costs 1.5 extra seconds.
        if let config = activeConfig, config.configType == .penalty {
            let penaltyPerSecond = abs(config.minutesPerMinute) * 60
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
