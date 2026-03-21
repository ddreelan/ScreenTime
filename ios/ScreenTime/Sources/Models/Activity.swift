import Foundation
import CoreLocation

enum ActivityType: String, Codable, CaseIterable {
    case walking = "walking"
    case running = "running"
    case cycling = "cycling"
    case meditation = "meditation"
    case reading = "reading"
    case exercise = "exercise"
    case outdoor = "outdoor"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .meditation: return "Meditation"
        case .reading: return "Reading"
        case .exercise: return "Exercise"
        case .outdoor: return "Outdoor Activity"
        case .custom: return "Custom Activity"
        }
    }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .meditation: return "brain.head.profile"
        case .reading: return "book.fill"
        case .exercise: return "dumbbell.fill"
        case .outdoor: return "sun.max.fill"
        case .custom: return "star.fill"
        }
    }

    var rewardMinutes: Double {
        switch self {
        case .walking: return 10
        case .running: return 20
        case .cycling: return 15
        case .meditation: return 10
        case .reading: return 15
        case .exercise: return 20
        case .outdoor: return 10
        case .custom: return 5
        }
    }
}

enum VerificationMethod: String, Codable {
    case tapCount = "tapCount"
    case scrollDetection = "scrollDetection"
    case geolocation = "geolocation"
    case accelerometer = "accelerometer"
    case manual = "manual"
}

enum ActivityStatus: String, Codable {
    case pending = "pending"
    case inProgress = "inProgress"
    case verified = "verified"
    case failed = "failed"
    case cancelled = "cancelled"
}

struct Activity: Codable, Identifiable {
    var id: UUID
    var type: ActivityType
    var customName: String?
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var verificationMethod: VerificationMethod
    var status: ActivityStatus
    var rewardEarned: TimeInterval // seconds of screen time earned
    var tapCount: Int
    var scrollDistance: Double
    var locationData: [String: Double]? // lat/lon
    var notes: String?

    init(
        id: UUID = UUID(),
        type: ActivityType,
        customName: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        verificationMethod: VerificationMethod = .tapCount,
        status: ActivityStatus = .pending,
        rewardEarned: TimeInterval = 0,
        tapCount: Int = 0,
        scrollDistance: Double = 0,
        locationData: [String: Double]? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.type = type
        self.customName = customName
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.verificationMethod = verificationMethod
        self.status = status
        self.rewardEarned = rewardEarned
        self.tapCount = tapCount
        self.scrollDistance = scrollDistance
        self.locationData = locationData
        self.notes = notes
    }

    var displayName: String {
        customName ?? type.displayName
    }
}
