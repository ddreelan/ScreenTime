import Foundation

struct ScreenTimeEntry: Codable, Identifiable {
    var id: UUID
    var appBundleIdentifier: String
    var appName: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval // in seconds
    var timeEarnedOrSpent: TimeInterval // positive = earned, negative = spent
    var date: Date

    init(
        id: UUID = UUID(),
        appBundleIdentifier: String,
        appName: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        timeEarnedOrSpent: TimeInterval = 0,
        date: Date = Calendar.current.startOfDay(for: Date())
    ) {
        self.id = id
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.timeEarnedOrSpent = timeEarnedOrSpent
        self.date = date
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct DailyScreenTimeSummary: Codable, Identifiable {
    var id: UUID
    var date: Date
    var totalAllocated: TimeInterval
    var totalUsed: TimeInterval
    var totalEarned: TimeInterval
    var totalPenalty: TimeInterval
    var entries: [ScreenTimeEntry]

    var remaining: TimeInterval {
        max(0, totalAllocated + totalEarned - totalUsed - totalPenalty)
    }

    var usagePercentage: Double {
        guard totalAllocated + totalEarned > 0 else { return 0 }
        return min(1.0, totalUsed / (totalAllocated + totalEarned))
    }

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        totalAllocated: TimeInterval = 2 * 3600,
        totalUsed: TimeInterval = 0,
        totalEarned: TimeInterval = 0,
        totalPenalty: TimeInterval = 0,
        entries: [ScreenTimeEntry] = []
    ) {
        self.id = id
        self.date = date
        self.totalAllocated = totalAllocated
        self.totalUsed = totalUsed
        self.totalEarned = totalEarned
        self.totalPenalty = totalPenalty
        self.entries = entries
    }
}
