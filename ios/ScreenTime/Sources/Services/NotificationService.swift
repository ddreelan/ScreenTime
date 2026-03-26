import Foundation
import UserNotifications

public class NotificationService: ObservableObject {
    public static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    public func requestPermission() {
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

    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String, delay: TimeInterval) {
        guard isAuthorized else { return }
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
