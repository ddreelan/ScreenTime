import SwiftUI

@main
@MainActor
struct ScreenTimeApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var authService = AuthService.shared

    @State private var showSplash = true
    private let urlHandler = URLHandler()

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else if !authService.isAuthenticated {
                    SignInView()
                        .environmentObject(authService)
                } else {
                    ContentView()
                        .environmentObject(dataStore)
                        .environmentObject(screenTimeService)
                        .environmentObject(notificationService)
                        .environmentObject(authService)
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
    }
}

@MainActor
class URLHandler {
    private var ignoringNextStart = false
    private var lastReturnedBundleID: String? = nil
    private var lastReturnTime: Date? = nil

    func handle(_ url: URL, screenTimeService: ScreenTimeService) {
        guard url.scheme == "screentime" else { return }

        switch url.host?.lowercased() {
        case "startapp":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let bundleID = components.queryItems?.first(where: { $0.name == "bundleID" })?.value {

                // If we just returned to this app within the last 2 seconds, ignore — it's the loop
                if let lastID = lastReturnedBundleID,
                   let lastTime = lastReturnTime,
                   lastID == bundleID,
                   Date().timeIntervalSince(lastTime) < 2.0 {
                    return
                }

                guard screenTimeService.activeAppBundleID != bundleID else { return }
                screenTimeService.setActiveApp(bundleID: bundleID)
                if !screenTimeService.isTracking {
                    screenTimeService.startTracking()
                }
                returnToApp(bundleID: bundleID)
            }
        case "stopapp":
            screenTimeService.setActiveApp(bundleID: nil)
            lastReturnedBundleID = nil
            lastReturnTime = nil
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let url = URL(string: scheme) else { return }

            // Record that we are returning to this app right now
            self.lastReturnedBundleID = bundleID
            self.lastReturnTime = Date()

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // canOpenURL failed — likely the scheme isn't in LSApplicationQueriesSchemes
                // Try opening without the check as a fallback
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        // Nothing worked — clear the record so the next open isn't blocked
                        self.lastReturnedBundleID = nil
                        self.lastReturnTime = nil
                    }
                }
            }
        }
    }
}
