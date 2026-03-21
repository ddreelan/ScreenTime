import XCTest
@testable import ScreenTime

final class DataStoreTests: XCTestCase {
    var dataStore: DataStore!

    override func setUp() {
        super.setUp()
        dataStore = DataStore.shared
    }

    func testAddActivity() {
        let activity = Activity(
            type: .walking,
            startTime: Date(),
            verificationMethod: .tapCount,
            status: .verified,
            rewardEarned: 600
        )
        let initialCount = dataStore.activities.count
        dataStore.addActivity(activity)
        XCTAssertEqual(dataStore.activities.count, initialCount + 1)
    }

    func testAppConfigManagement() {
        let config = AppConfig(
            bundleIdentifier: "com.test.app",
            appName: "Test App",
            configType: .reward,
            minutesPerMinute: 1.5
        )
        let initialCount = dataStore.appConfigs.count
        dataStore.addAppConfig(config)
        XCTAssertEqual(dataStore.appConfigs.count, initialCount + 1)

        var updated = config
        updated.minutesPerMinute = 2.0
        dataStore.updateAppConfig(updated)
        let found = dataStore.appConfigs.first { $0.id == config.id }
        XCTAssertEqual(found?.minutesPerMinute, 2.0)

        dataStore.removeAppConfig(config.id)
        XCTAssertFalse(dataStore.appConfigs.contains { $0.id == config.id })
    }

    func testDailyScreenTimeSummaryCalculation() {
        let summary = DailyScreenTimeSummary(
            totalAllocated: 7200,  // 2 hours
            totalUsed: 3600,       // 1 hour
            totalEarned: 1800,     // 30 minutes
            totalPenalty: 600      // 10 minutes
        )
        XCTAssertEqual(summary.remaining, 7200 + 1800 - 3600 - 600)
        XCTAssertLessThanOrEqual(summary.usagePercentage, 1.0)
    }

    func testActivityRewardCalculation() {
        let service = ActivityVerificationService.shared
        let reward = service.calculateReward(for: .walking, duration: 15 * 60)
        XCTAssertGreaterThan(reward, 0)
    }
}
