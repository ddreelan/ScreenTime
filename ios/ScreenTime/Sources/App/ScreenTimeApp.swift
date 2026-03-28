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
                // Return to the tracked app after a brief delay
                returnToApp(bundleID: bundleID)
            }
        case "stopapp":
            screenTimeService.setActiveApp(bundleID: nil)
        default:
            break
        }
    }

    private func returnToApp(bundleID: String) {
        // Known URL schemes for popular apps
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
            "com.apple.mobilemail": "message://",
            "com.apple.mobilesafari": "https://",
            "com.tiktok.TikTok": "snssdk1128://",
            "com.zhiliaoapp.musically": "snssdk1128://",
            "com.discord.discord": "discord://",
            "com.snapchat.snapchat": "snapchat://",
        ]

        let scheme = knownSchemes[bundleID] ?? "\(bundleID)://"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
