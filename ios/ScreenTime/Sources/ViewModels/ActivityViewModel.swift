import Foundation
import Combine

class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var currentActivity: Activity?
    @Published var isVerifying: Bool = false
    @Published var verificationProgress: Double = 0
    @Published var verificationMessage: String = ""
    @Published var selectedActivityType: ActivityType = .walking
    @Published var recentlyEarned: TimeInterval = 0
    @Published var showRewardAnimation: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let dataStore = DataStore.shared
    private let verificationService = ActivityVerificationService.shared
    private let screenTimeService = ScreenTimeService.shared

    init() {
        setupBindings()
        activities = dataStore.activities
    }

    private func setupBindings() {
        dataStore.$activities
            .receive(on: DispatchQueue.main)
            .assign(to: &$activities)

        verificationService.$isVerifying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isVerifying)

        verificationService.$verificationProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$verificationProgress)

        verificationService.$verificationMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$verificationMessage)
    }

    func startActivity(type: ActivityType) {
        let activity = Activity(
            type: type,
            startTime: Date(),
            verificationMethod: verificationMethodFor(type),
            status: .inProgress
        )
        currentActivity = activity
        dataStore.addActivity(activity)

        verificationService.startVerification(for: activity) { [weak self] success, duration in
            self?.completeActivity(success: success, duration: duration)
        }
    }

    func recordTap() {
        verificationService.recordTap()
    }

    func recordScroll(distance: Double) {
        verificationService.recordScroll(distance: distance)
    }

    func completeManualActivity() {
        verificationService.completeManualVerification()
    }

    func cancelActivity() {
        verificationService.cancelVerification()
        if let activity = currentActivity {
            var cancelled = activity
            cancelled.status = .cancelled
            cancelled.endTime = Date()
            dataStore.updateActivity(cancelled)
        }
        currentActivity = nil
    }

    private func completeActivity(success: Bool, duration: TimeInterval) {
        guard var activity = currentActivity else { return }
        activity.endTime = Date()
        activity.duration = duration
        activity.status = success ? .verified : .failed

        if success {
            let reward = verificationService.calculateReward(for: activity.type, duration: duration)
            activity.rewardEarned = reward
            recentlyEarned = reward
            screenTimeService.addEarnedTime(reward)
            showRewardAnimation = true
            NotificationService.shared.sendActivityCompletedNotification(
                activityName: activity.displayName,
                rewardMinutes: reward / 60
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showRewardAnimation = false
            }
        }

        dataStore.updateActivity(activity)
        currentActivity = nil
    }

    private func verificationMethodFor(_ type: ActivityType) -> VerificationMethod {
        switch type {
        case .walking, .running, .cycling, .outdoor:
            return .accelerometer
        case .reading:
            return .scrollDetection
        case .meditation:
            return .tapCount
        case .exercise:
            return .accelerometer
        case .custom:
            return .manual
        }
    }

    var todayActivities: [Activity] {
        let today = Calendar.current.startOfDay(for: Date())
        return activities
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }
            .sorted { $0.startTime > $1.startTime }
    }

    var todayEarned: TimeInterval {
        todayActivities
            .filter { $0.status == .verified }
            .reduce(0) { $0 + $1.rewardEarned }
    }
}
