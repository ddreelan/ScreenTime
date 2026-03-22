import Foundation
import CoreMotion
import CoreLocation
import Combine

class ActivityVerificationService: NSObject, ObservableObject {
    static let shared = ActivityVerificationService()

    @Published var currentTapCount: Int = 0
    @Published var currentScrollDistance: Double = 0
    @Published var isVerifying: Bool = false
    @Published var verificationProgress: Double = 0
    @Published var verificationMessage: String = ""

    private let pedometer = CMPedometer()
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()

    // Thresholds for verification
    let requiredTaps = 20
    let requiredScrollDistance: Double = 500

    private var verificationCompletion: ((Bool, TimeInterval) -> Void)?
    private var activityStartTime: Date?

    override private init() {
        super.init()
        locationManager.delegate = self
    }

    func startVerification(for activity: Activity, completion: @escaping (Bool, TimeInterval) -> Void) {
        isVerifying = true
        currentTapCount = 0
        currentScrollDistance = 0
        verificationProgress = 0
        activityStartTime = Date()
        verificationCompletion = completion

        switch activity.verificationMethod {
        case .tapCount:
            startTapVerification()
        case .scrollDetection:
            startScrollVerification()
        case .geolocation:
            startLocationVerification()
        case .accelerometer:
            startAccelerometerVerification()
        case .manual:
            verificationMessage = "Activity started. Tap 'Complete' when done."
        }
    }

    func recordTap() {
        guard isVerifying else { return }
        currentTapCount += 1
        let progress = Double(currentTapCount) / Double(requiredTaps)
        verificationProgress = min(1.0, progress)
        verificationMessage = "\(currentTapCount)/\(requiredTaps) interactions recorded"

        if currentTapCount >= requiredTaps {
            completeVerification(success: true)
        }
    }

    func recordScroll(distance: Double) {
        guard isVerifying else { return }
        currentScrollDistance += distance
        let progress = currentScrollDistance / requiredScrollDistance
        verificationProgress = min(1.0, progress)
        verificationMessage = "Scroll progress: \(Int(verificationProgress * 100))%"

        if currentScrollDistance >= requiredScrollDistance {
            completeVerification(success: true)
        }
    }

    func completeManualVerification() {
        completeVerification(success: true)
    }

    func cancelVerification() {
        isVerifying = false
        motionManager.stopAccelerometerUpdates()
        locationManager.stopUpdatingLocation()
        verificationCompletion?(false, 0)
        verificationCompletion = nil
    }

    private func startTapVerification() {
        verificationMessage = "Tap the screen \(requiredTaps) times to verify your activity"
    }

    private func startScrollVerification() {
        verificationMessage = "Scroll through content to verify your reading activity"
    }

    private func startLocationVerification() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        verificationMessage = "Detecting your outdoor activity via GPS..."
    }

    private func startAccelerometerVerification() {
        guard motionManager.isAccelerometerAvailable else {
            verificationMessage = "Accelerometer not available. Please use tap verification."
            return
        }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let magnitude = sqrt(pow(data.acceleration.x, 2) +
                                pow(data.acceleration.y, 2) +
                                pow(data.acceleration.z, 2))
            if magnitude > 1.5 { // Motion detected
                self.currentTapCount += 1
                let progress = Double(self.currentTapCount) / Double(self.requiredTaps * 5)
                self.verificationProgress = min(1.0, progress)
                if self.verificationProgress >= 1.0 {
                    self.completeVerification(success: true)
                }
            }
        }
        verificationMessage = "Move your device to verify physical activity..."
    }

    private func completeVerification(success: Bool) {
        isVerifying = false
        motionManager.stopAccelerometerUpdates()
        locationManager.stopUpdatingLocation()

        let duration = activityStartTime.map { Date().timeIntervalSince($0) } ?? 0
        verificationCompletion?(success, duration)
        verificationCompletion = nil

        if success {
            verificationMessage = "Activity verified! Screen time earned."
        }
    }

    func calculateReward(for activityType: ActivityType, duration: TimeInterval) -> TimeInterval {
        let baseReward = activityType.rewardMinutes * 60 // Convert to seconds
        let durationMultiplier = min(duration / (15 * 60), 2.0) // Cap at 2x for activities > 15 min
        return baseReward * durationMultiplier
    }
}

extension ActivityVerificationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let _ = locations.last else { return }
        currentTapCount += 1
        let progress = Double(currentTapCount) / Double(requiredTaps)
        verificationProgress = min(1.0, progress)
        verificationMessage = "GPS signal strong. Keep moving..."

        if verificationProgress >= 1.0 {
            completeVerification(success: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        verificationMessage = "GPS unavailable. Switch to manual verification."
    }
}
