import Foundation

struct TimelineDataPoint: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var remainingSeconds: Double
    var activeAppName: String?
    var activeAppBundleID: String?
    var delta: Double // positive = gaining, negative = losing, 0 = inactive

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        remainingSeconds: Double = 0,
        activeAppName: String? = nil,
        activeAppBundleID: String? = nil,
        delta: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.remainingSeconds = remainingSeconds
        self.activeAppName = activeAppName
        self.activeAppBundleID = activeAppBundleID
        self.delta = delta
    }
}
