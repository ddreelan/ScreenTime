import Foundation
import Combine
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var appConfigs: [AppConfig] = []
    @Published var rewardApps: [AppConfig] = []
    @Published var penaltyApps: [AppConfig] = []
    @Published var userProfile: UserProfile?
    @Published var dailyLimitHours: Double = 2.0
    @Published var dailyLimitMinutes: Double = 0.0
    @Published var isAddingApp: Bool = false
    @Published var editingConfig: AppConfig?

    private var cancellables = Set<AnyCancellable>()
    private let dataStore = DataStore.shared

    init() {
        setupBindings()
        refresh()
    }

    private func setupBindings() {
        dataStore.$appConfigs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] configs in
                self?.appConfigs = configs
                self?.rewardApps = configs.filter { $0.configType == .reward }
                self?.penaltyApps = configs.filter { $0.configType == .penalty }
            }
            .store(in: &cancellables)

        dataStore.$userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.userProfile = profile
                if let limit = profile?.dailyScreenTimeLimit {
                    self?.dailyLimitHours = Double(Int(limit) / 3600)
                    self?.dailyLimitMinutes = Double((Int(limit) % 3600) / 60)
                }
            }
            .store(in: &cancellables)
    }

    func refresh() {
        appConfigs = dataStore.appConfigs
        rewardApps = appConfigs.filter { $0.configType == .reward }
        penaltyApps = appConfigs.filter { $0.configType == .penalty }
        userProfile = dataStore.userProfile
    }

    func addOrUpdateAppConfig(_ config: AppConfig) {
        if appConfigs.contains(where: { $0.id == config.id }) {
            dataStore.updateAppConfig(config)
        } else {
            dataStore.addAppConfig(config)
        }
    }

    func removeAppConfig(at offsets: IndexSet, from type: AppConfigType) {
        let appsOfType = appConfigs.filter { $0.configType == type }
        for index in offsets {
            if index < appsOfType.count {
                dataStore.removeAppConfig(appsOfType[index].id)
            }
        }
    }

    func saveDailyLimit() {
        let totalSeconds = (dailyLimitHours * 3600) + (dailyLimitMinutes * 60)
        if var profile = userProfile {
            profile.dailyScreenTimeLimit = totalSeconds
            profile.updatedAt = Date()
            dataStore.saveUserProfile(profile)
        } else {
            let newProfile = UserProfile(name: "User", age: 18, dailyScreenTimeLimit: totalSeconds)
            dataStore.saveUserProfile(newProfile)
        }
        dataStore.todaySummary = DailyScreenTimeSummary(
            id: dataStore.todaySummary.id,
            date: dataStore.todaySummary.date,
            totalAllocated: totalSeconds,
            totalUsed: dataStore.todaySummary.totalUsed,
            totalEarned: dataStore.todaySummary.totalEarned,
            totalPenalty: dataStore.todaySummary.totalPenalty,
            entries: dataStore.todaySummary.entries
        )
        dataStore.saveSummary()
    }

    func toggleAppEnabled(_ config: AppConfig) {
        var updated = config
        updated.isEnabled.toggle()
        dataStore.updateAppConfig(updated)
    }
}
