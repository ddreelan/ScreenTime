import SwiftUI

@main
@MainActor
struct ScreenTimeApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(screenTimeService)
                .environmentObject(notificationService)
                .onAppear {
                    notificationService.requestPermission()
                    screenTimeService.startTracking()
                    LocalServer.shared.start()
                }
                .onOpenURL { url in
                    // Keep URL scheme as fallback for manual testing
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "screentime" else { return }

        switch url.host?.lowercased() {
        case "startapp":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let bundleID = components.queryItems?.first(where: { $0.name == "bundleID" })?.value {
                screenTimeService.setActiveApp(bundleID: bundleID)
                if !screenTimeService.isTracking {
                    screenTimeService.startTracking()
                }
            }
        case "stopapp":
            screenTimeService.setActiveApp(bundleID: nil)
        default:
            break
        }
    }
}
