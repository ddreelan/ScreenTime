import Foundation

/// Lightweight model representing per-app time impact for the widget.
struct WidgetAppInfo: Codable {
    var appName: String
    var iconName: String?
    var minutesPerMinute: Double
    /// "reward" or "penalty"
    var configType: String
}

/// Snapshot of data shared between the main app and the widget via App Groups.
struct WidgetData: Codable {
    static let appGroupID = "group.com.ddreelan.ScreenTime"
    static let userDefaultsKey = "screentime_widget_data"

    var remainingSeconds: TimeInterval
    var totalEarned: TimeInterval
    var totalPenalty: TimeInterval
    var totalAllocated: TimeInterval
    var totalUsed: TimeInterval
    var topApps: [WidgetAppInfo]
    var lastUpdated: Date

    init(
        remainingSeconds: TimeInterval = 0,
        totalEarned: TimeInterval = 0,
        totalPenalty: TimeInterval = 0,
        totalAllocated: TimeInterval = 7200,
        totalUsed: TimeInterval = 0,
        topApps: [WidgetAppInfo] = [],
        lastUpdated: Date = Date()
    ) {
        self.remainingSeconds = remainingSeconds
        self.totalEarned = totalEarned
        self.totalPenalty = totalPenalty
        self.totalAllocated = totalAllocated
        self.totalUsed = totalUsed
        self.topApps = topApps
        self.lastUpdated = lastUpdated
    }

    /// Read widget data from the shared App Group container.
    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Write widget data to the shared App Group container.
    func save() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(self) else {
            return
        }
        defaults.set(data, forKey: userDefaultsKey)
    }
}
