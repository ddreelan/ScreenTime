import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }

    func sendLimitReachedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Screen Time Limit Reached"
        content.body = "You've used all your screen time for today. Complete activities to earn more!"
        content.sound = .default
        content.badge = 1
        scheduleNotification(content: content, identifier: "limitReached", delay: 0)
    }

    func sendFiveMinuteWarning() {
        let content = UNMutableNotificationContent()
        content.title = "5 Minutes Remaining"
        content.body = "You have 5 minutes of screen time left. Time to take a break!"
        content.sound = .default
        scheduleNotification(content: content, identifier: "fiveMinuteWarning", delay: 0)
    }

    func scheduleBreakReminder(after minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a Break! 🌱"
        content.body = "You've been on your screen for a while. Step outside or do some exercise to earn more time!"
        content.sound = .default
        scheduleNotification(content: content, identifier: "breakReminder", delay: TimeInterval(minutes * 60))
    }

    func sendActivityCompletedNotification(activityName: String, rewardMinutes: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Activity Complete! 🎉"
        content.body = "Great job completing \(activityName)! You earned \(Int(rewardMinutes)) minutes of screen time."
        content.sound = .default
        scheduleNotification(content: content, identifier: "activityCompleted_\(Date().timeIntervalSince1970)", delay: 0)
    }

    func sendStreakNotification(days: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(days)-Day Streak!"
        content.body = "Amazing! You've managed your screen time for \(days) days in a row. Keep it up!"
        content.sound = .default
        scheduleNotification(content: content, identifier: "streak_\(days)", delay: 0)
    }

    func scheduleDailyMotivation() {
        let messages = [
            "Start your day right! Complete an activity to earn extra screen time.",
            "Remember: balance is key. Take breaks and move around!",
            "You're doing great! Keep managing your screen time wisely.",
        ]
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder 💪"
        content.body = messages.randomElement() ?? messages[0]
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMotivation", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Sent immediately when the user marks a reward or penalty app as active.
    func sendAppStartedNotification(appName: String, configType: AppConfigType, ratePerMinute: Double, remainingSeconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        let remaining = formatTime(remainingSeconds)

        switch configType {
        case .reward:
            content.title = "🟢 Earning Time — \(appName)"
            content.body = "You're earning +\(formatRate(ratePerMinute)) per minute. Screen time remaining: \(remaining)."
        case .penalty:
            content.title = "🔴 Losing Time — \(appName)"
            content.body = "This app costs \(formatRate(abs(ratePerMinute))) per minute. Screen time remaining: \(remaining)."
        case .neutral:
            return
        }

        content.sound = .default
        // Replace any previous "app started" notification so they don't stack
        scheduleNotification(content: content, identifier: "appStarted", delay: 0)
    }

    /// Sent every 5 minutes while a reward/penalty app is active, showing a running tally.
    func sendAppUpdateNotification(appName: String, configType: AppConfigType, earnedOrCostSeconds: TimeInterval, remainingSeconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        let remaining = formatTime(remainingSeconds)
        let amount = formatTime(abs(earnedOrCostSeconds))

        switch configType {
        case .reward:
            content.title = "🟢 Still Earning — \(appName)"
            content.body = "+\(amount) earned so far. Screen time remaining: \(remaining)."
        case .penalty:
            content.title = "🔴 Still Losing Time — \(appName)"
            content.body = "\(amount) spent so far. Screen time remaining: \(remaining)."
        case .neutral:
            return
        }

        content.sound = .default
        // Use a timestamped identifier so each update shows as a fresh notification
        scheduleNotification(content: content, identifier: "appUpdate_\(Date().timeIntervalSince1970)", delay: 0)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(abs(seconds)) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func formatRate(_ ratePerMinute: Double) -> String {
        // ratePerMinute is in minutes of screen time per minute of app use
        if ratePerMinute == Double(Int(ratePerMinute)) {
            return "\(Int(ratePerMinute))m"
        }
        return String(format: "%.1fm", ratePerMinute)
    }

    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String, delay: TimeInterval) {
        guard isAuthorized else { return }
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func sendAppExitSummaryNotification(totalUsed: TimeInterval, totalPenalty: TimeInterval, remaining: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "📊 Session Summary"
        content.body = "Used: \(formatTime(totalUsed)) • Penalty: \(formatTime(totalPenalty)) • Remaining: \(formatTime(remaining))"
        content.sound = .default
        scheduleNotification(content: content, identifier: "appExitSummary", delay: 0)
    }
}
