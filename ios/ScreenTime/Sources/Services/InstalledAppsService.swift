import UIKit

final class InstalledAppsService {

    static let shared = InstalledAppsService()
    private init() {}

    // MARK: - Curated app list

    let knownApps: [InstalledAppInfo] = [
        // Social
        InstalledAppInfo(id: "com.zhiliaoapp.musically",   name: "TikTok",      urlScheme: "tiktok://",     sfSymbol: "music.note",             category: "Social"),
        InstalledAppInfo(id: "com.burbn.instagram",        name: "Instagram",   urlScheme: "instagram://",  sfSymbol: "camera.fill",            category: "Social"),
        InstalledAppInfo(id: "com.twitter.twitter",        name: "Twitter / X", urlScheme: "twitter://",    sfSymbol: "bird.fill",              category: "Social"),
        InstalledAppInfo(id: "com.facebook.Facebook",      name: "Facebook",    urlScheme: "fb://",         sfSymbol: "person.2.fill",          category: "Social"),
        InstalledAppInfo(id: "com.toyopagroup.picaboo",    name: "Snapchat",    urlScheme: "snapchat://",   sfSymbol: "bolt.fill",              category: "Social"),
        InstalledAppInfo(id: "net.whatsapp.WhatsApp",      name: "WhatsApp",    urlScheme: "whatsapp://",   sfSymbol: "message.fill",           category: "Social"),
        InstalledAppInfo(id: "com.reddit.Reddit",          name: "Reddit",      urlScheme: "reddit://",     sfSymbol: "bubble.left.and.bubble.right.fill", category: "Social"),
        InstalledAppInfo(id: "com.hammerandchisel.discord", name: "Discord",    urlScheme: "discord://",    sfSymbol: "gamecontroller.fill",    category: "Social"),
        InstalledAppInfo(id: "com.pinterest.Pinterest",    name: "Pinterest",   urlScheme: "pinterest://",  sfSymbol: "pin.fill",               category: "Social"),
        InstalledAppInfo(id: "com.linkedin.LinkedIn",      name: "LinkedIn",    urlScheme: "linkedin://",   sfSymbol: "briefcase.fill",         category: "Social"),

        // Entertainment
        InstalledAppInfo(id: "com.google.ios.youtube",     name: "YouTube",     urlScheme: "youtube://",    sfSymbol: "play.rectangle.fill",    category: "Entertainment"),
        InstalledAppInfo(id: "com.netflix.Netflix",        name: "Netflix",     urlScheme: "netflix://",    sfSymbol: "tv.fill",                category: "Entertainment"),
        InstalledAppInfo(id: "com.spotify.client",         name: "Spotify",     urlScheme: "spotify://",    sfSymbol: "music.quarternote.3",    category: "Entertainment"),
        InstalledAppInfo(id: "tv.twitch.twitch",           name: "Twitch",      urlScheme: "twitch://",     sfSymbol: "video.fill",             category: "Entertainment"),
        InstalledAppInfo(id: "com.apple.podcasts",         name: "Podcasts",    urlScheme: "podcast://",    sfSymbol: "waveform",               category: "Entertainment"),

        // Health & Fitness
        InstalledAppInfo(id: "com.apple.Health",           name: "Health",      urlScheme: "x-apple-health://", sfSymbol: "heart.fill",         category: "Health"),
        InstalledAppInfo(id: "com.apple.fitness",          name: "Fitness",     urlScheme: "x-apple-fitness://", sfSymbol: "figure.walk",        category: "Health"),
        InstalledAppInfo(id: "com.headspace.headspace",    name: "Headspace",   urlScheme: "headspace://",  sfSymbol: "brain.head.profile",     category: "Health"),
        InstalledAppInfo(id: "com.calm.ios.calm",          name: "Calm",        urlScheme: "calm://",       sfSymbol: "moon.stars.fill",        category: "Health"),
        InstalledAppInfo(id: "com.noom.Noom",              name: "Noom",        urlScheme: "noom://",       sfSymbol: "scalemass.fill",         category: "Health"),

        // Education
        InstalledAppInfo(id: "com.duolingo.duolingo",      name: "Duolingo",    urlScheme: "duolingo://",   sfSymbol: "book.fill",              category: "Education"),
        InstalledAppInfo(id: "com.khanacademy.khanacademy", name: "Khan Academy", urlScheme: "khanacademy://", sfSymbol: "graduationcap.fill",  category: "Education"),
        InstalledAppInfo(id: "com.Quizlet.iphone",         name: "Quizlet",     urlScheme: "quizlet://",    sfSymbol: "doc.text.fill",          category: "Education"),

        // Productivity
        InstalledAppInfo(id: "com.apple.mobilesafari",     name: "Safari",      urlScheme: "https://",      sfSymbol: "safari.fill",            category: "Productivity"),
        InstalledAppInfo(id: "com.apple.Maps",             name: "Maps",        urlScheme: "maps://",       sfSymbol: "map.fill",               category: "Productivity"),
        InstalledAppInfo(id: "com.microsoft.Office.Word",  name: "Word",        urlScheme: "ms-word://",    sfSymbol: "doc.fill",               category: "Productivity"),
        InstalledAppInfo(id: "com.microsoft.Office.Excel", name: "Excel",       urlScheme: "ms-excel://",   sfSymbol: "tablecells.fill",        category: "Productivity"),
        InstalledAppInfo(id: "com.google.Docs",            name: "Google Docs", urlScheme: "googledocs://", sfSymbol: "doc.text.fill",          category: "Productivity"),

        // Gaming
        InstalledAppInfo(id: "com.supercell.clashofclans", name: "Clash of Clans", urlScheme: "clashofclans://", sfSymbol: "gamecontroller.fill", category: "Gaming"),
        InstalledAppInfo(id: "com.roblox.robloxmobile",   name: "Roblox",      urlScheme: "roblox://",     sfSymbol: "cube.fill",              category: "Gaming"),
        InstalledAppInfo(id: "com.minecraft.ipad",        name: "Minecraft",   urlScheme: "minecraft://",  sfSymbol: "square.grid.3x3.fill",   category: "Gaming"),
        InstalledAppInfo(id: "com.epicgames.fortnite",    name: "Fortnite",    urlScheme: "fortnite://",   sfSymbol: "bolt.circle.fill",       category: "Gaming"),
    ]

    // MARK: - Detection

    /// Returns apps from the curated list that are detected as installed via canOpenURL.
    /// Falls back to the full curated list when nothing is detected (e.g. Simulator).
    func detectInstalledApps() -> [InstalledAppInfo] {
        let installed = knownApps.filter { app in
            guard let url = URL(string: app.urlScheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
        return installed.isEmpty ? knownApps : installed
    }
}
