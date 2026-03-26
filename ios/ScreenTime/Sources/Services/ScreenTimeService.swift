import Foundation
import Combine

public class ScreenTimeService: ObservableObject {
    public static let shared = ScreenTimeService()

    @Published var isTracking = false
    @Published var currentAppTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 0

    private var trackingTimer: Timer?
    private var dataStore: DataStore { DataStore.shared }
    private var cancellables = Set<AnyCancellable>()

    private init() {
        updateRemainingTime()
    }

    public func startTracking() {
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

    private func tick() {
        currentAppTime += 1
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
