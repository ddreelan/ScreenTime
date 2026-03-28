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
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    /// Handles deep links of the form:
    ///   screentime://startApp?bundleID=com.google.ios.youtube
    ///   screentime://stopApp
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "screentime" else { return }

        // url.host is lowercased by iOS, so compare lowercase
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
