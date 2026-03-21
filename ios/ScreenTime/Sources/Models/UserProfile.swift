import Foundation

struct UserProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var age: Int
    var dailyScreenTimeLimit: TimeInterval // in seconds
    var goals: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        dailyScreenTimeLimit: TimeInterval = 2 * 3600, // Default 2 hours
        goals: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.dailyScreenTimeLimit = dailyScreenTimeLimit
        self.goals = goals
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var dailyScreenTimeLimitFormatted: String {
        let hours = Int(dailyScreenTimeLimit) / 3600
        let minutes = (Int(dailyScreenTimeLimit) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
