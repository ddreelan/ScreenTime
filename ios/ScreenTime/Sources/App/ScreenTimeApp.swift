import SwiftUI

@main
@MainActor
struct ScreenTimeApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @StateObject private var notificationService = NotificationService.shared

    /// When true, the next startApp URL is ignored because we triggered
    /// the app open ourselves to return the user after tracking started.
    @State private var ignoringNextStart = false

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
            // Skip if we opened the app ourselves to return the user
            if ignoringNextStart {
                ignoringNextStart = false
                return
            }
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let bundleID = components.queryItems?.first(where: { $0.name == "bundleID" })?.value {
                // Only start if not already tracking this exact app
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
            "com.apple.mobilemail": "message://",
            "com.apple.mobilesafari": "https://",
            "com.tiktok.TikTok": "snssdk1128://",
            "com.zhiliaoapp.musically": "snssdk1128://",
            "com.discord.discord": "discord://",
            "com.snapchat.snapchat": "snapchat://",
        ]

        let scheme = knownSchemes[bundleID] ?? "\(bundleID)://"

        // Set the flag BEFORE opening the app so it's ready when the
        // automation fires again
        ignoringNextStart = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // If we couldn't open the app, clear the flag so future
                // legitimate opens aren't accidentally ignored
                ignoringNextStart = false
            }
        }

        // Safety reset — if the automation never fires again (e.g. app
        // didn't reopen), clear the flag after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            ignoringNextStart = false
        }
    }
}
