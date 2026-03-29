import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var todaySummary: DailyScreenTimeSummary = DailyScreenTimeSummary()
    @Published var remainingTimeFormatted: String = "0m"
    @Published var usedTimeFormatted: String = "0m"
    @Published var earnedTimeFormatted: String = "0m"
    @Published var progressValue: Double = 0.0
    @Published var motivationalMessage: String = ""
    @Published var recentActivities: [Activity] = []
    @Published var topPenaltyApps: [AppConfig] = []
    @Published var recentGainsPenalties: [GainPenaltyEvent] = []

    private var cancellables = Set<AnyCancellable>()
    private let dataStore = DataStore.shared
    private let screenTimeService = ScreenTimeService.shared

    init() {
        setupBindings()
        refresh()
    }

    private func setupBindings() {
        dataStore.$todaySummary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.todaySummary = summary
                self?.updateFormattedValues()
            }
            .store(in: &cancellables)

        dataStore.$activities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activities in
                let today = Calendar.current.startOfDay(for: Date())
                let todayActivities = activities
                    .filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }
                self?.recentActivities = todayActivities
                    .sorted { $0.startTime > $1.startTime }
                    .prefix(3)
                    .map { $0 }
                self?.deriveGainPenaltyEvents(from: todayActivities)
            }
            .store(in: &cancellables)

        dataStore.$appConfigs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] configs in
                self?.topPenaltyApps = configs
                    .filter { $0.configType == .penalty && $0.isEnabled }
                    .sorted { abs($0.minutesPerMinute) > abs($1.minutesPerMinute) }
                    .prefix(3)
                    .map { $0 }
            }
            .store(in: &cancellables)
    }

    private func deriveGainPenaltyEvents(from activities: [Activity]) {
        var events: [GainPenaltyEvent] = []
        for activity in activities where activity.status == .verified && activity.rewardEarned > 0 {
            let event = GainPenaltyEvent(
                id: activity.id.uuidString + "_act",
                type: .activityReward,
                activityName: activity.displayName,
                secondsDelta: Int(activity.rewardEarned),
                timestamp: activity.endTime ?? activity.startTime,
                icon: activity.type.icon
            )
            events.append(event)
        }
        recentGainsPenalties = Array(
            events.sorted { $0.timestamp > $1.timestamp }.prefix(5)
        )
    }

    func refresh() {
        todaySummary = dataStore.todaySummary
        updateFormattedValues()
    }

    private func updateFormattedValues() {
        remainingTimeFormatted = formatTime(todaySummary.remaining)
        usedTimeFormatted = formatTime(todaySummary.totalUsed)
        earnedTimeFormatted = formatTime(todaySummary.totalEarned)
        progressValue = todaySummary.usagePercentage
        motivationalMessage = generateMotivationalMessage()
    }

    private func generateMotivationalMessage() -> String {
        let remaining = todaySummary.remaining
        if remaining <= 0 {
            return "Screen time limit reached! Complete activities to earn more. 💪"
        } else if remaining < 1800 {
            return "Less than 30 minutes left. Consider taking a break! 🌿"
        } else if todaySummary.totalEarned > 0 {
            return "Great job earning extra time through activities! 🌟"
        } else {
            return "Complete activities to earn bonus screen time! 🎯"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var progressColor: Color {
        if progressValue < 0.6 {
            return .green
        } else if progressValue < 0.85 {
            return .orange
        } else {
            return .red
        }
    }
}
