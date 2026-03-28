import SwiftUI

@main
@MainActor
struct ScreenTimeApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @StateObject private var notificationService = NotificationService.shared

    /// Stored as a class-level property so it reliably persists between URL calls.
    private let urlHandler = URLHandler()

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
                    urlHandler.handle(url, screenTimeService: screenTimeService)
                }
        }
    }
}

/// Handles incoming deep links with loop-prevention logic.
/// Lives as a class so its state reliably persists across calls.
@MainActor
class URLHandler {
    private var ignoringNextStart = false

    func handle(_ url: URL, screenTimeService: ScreenTimeService) {
        guard url.scheme == "screentime" else { return }

        switch url.host?.lowercased() {
        case "startapp":
            if ignoringNextStart {
                ignoringNextStart = false
                return
            }
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let bundleID = components.queryItems?.first(where: { $0.name == "bundleID" })?.value {
                guard screenTimeService.activeAppBundleID != bundleID else { return }
                screenTimeService.setActiveApp(bundleID: bundleID)
                if !screenTimeService.isTracking {
                    screenTimeService.startTracking()
                }
                returnToApp(bundleID: bundleID)
            }
        case "stopapp":
            screenTimeService.setActiveApp(bundleID: nil)
        default:
            break
        }
    }

    private func returnToApp(bundleID: String) {
        let knownSchemes: [String: String] = [
            "com.google.ios.youtube": "youtube://",
            "com.instagram.mainapp": "instagram://",
            "com.burbn.instagram": "instagram://",
            "com.facebook.Facebook": "fb://",
            "com.atebits.Tweetie2": "twitter://",
            "com.twitter.twitter-iphone": "twitter://",
            "com.reddit.reddit": "reddit://",
            "com.netflix.Netflix": "nflx://",
            "com.spotify.client": "spotify://",
            "com.apple.mobilesafari": "https://",
            "com.tiktok.TikTok": "snssdk1128://",
            "com.zhiliaoapp.musically": "snssdk1128://",
            "com.discord.discord": "discord://",
            "com.snapchat.snapchat": "snapchat://",
        ]

        let scheme = knownSchemes[bundleID] ?? "\(bundleID)://"

        // Set flag BEFORE the delay so it's ready when the automation fires
        ignoringNextStart = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self.ignoringNextStart = false
            }
        }

        // Safety reset after 3 seconds in case the automation never fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.ignoringNextStart = false
        }
    }
}
