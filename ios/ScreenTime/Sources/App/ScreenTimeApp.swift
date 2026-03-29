import SwiftUI

@main
@MainActor
struct ScreenTimeApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var authService = AuthService.shared

    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

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
                            URLHandler.shared.handle(url, screenTimeService: screenTimeService)
                        }
                }
            }
            .modifier(ScenePhaseChangeModifier(scenePhase: scenePhase) { newPhase in
                if newPhase == .background {
                    let summary = dataStore.todaySummary
                    notificationService.sendAppExitSummaryNotification(
                        totalUsed: summary.totalUsed,
                        totalPenalty: summary.totalPenalty,
                        remaining: summary.remaining
                    )
                }
            })
        }
    }
}

private struct ScenePhaseChangeModifier: ViewModifier {
    let scenePhase: ScenePhase
    let action: (ScenePhase) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: scenePhase) { _, newPhase in action(newPhase) }
        } else {
            content.onChange(of: scenePhase) { newPhase in action(newPhase) }
        }
    }
}

@MainActor
class URLHandler {
    static let shared = URLHandler()
    private init() {}

    func handle(_ url: URL, screenTimeService: ScreenTimeService) {
        guard url.scheme == "screentime" else { return }

        switch url.host?.lowercased() {
        case "startapp":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let bundleID = components.queryItems?.first(where: { $0.name == "bundleID" })?.value {
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

    func returnToApp(bundleID: String) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let url = URL(string: scheme) else { return }
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("[URLHandler] Failed to open \(scheme) for bundleID: \(bundleID)")
                }
            }
        }
    }
}
