import WidgetKit
import SwiftUI

// MARK: - Shared Types (duplicated from main app for widget process isolation)

struct WidgetAppInfo: Codable {
    var appName: String
    var iconName: String?
    var minutesPerMinute: Double
    var configType: String
}

struct WidgetData: Codable {
    static let appGroupID = "group.com.ddreelan.ScreenTime"
    static let userDefaultsKey = "screentime_widget_data"

    var remainingSeconds: TimeInterval
    var totalEarned: TimeInterval
    var totalPenalty: TimeInterval
    var totalAllocated: TimeInterval
    var totalUsed: TimeInterval
    var topApps: [WidgetAppInfo]
    var lastUpdated: Date

    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}

// MARK: - Timeline Entry

struct ScreenTimeWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider

struct ScreenTimeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScreenTimeWidgetEntry {
        ScreenTimeWidgetEntry(date: Date(), widgetData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScreenTimeWidgetEntry) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        completion(ScreenTimeWidgetEntry(date: Date(), widgetData: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScreenTimeWidgetEntry>) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        let entry = ScreenTimeWidgetEntry(date: Date(), widgetData: data)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct ScreenTimeWidgetEntryView: View {
    var entry: ScreenTimeWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.widgetData)
        case .systemMedium:
            MediumWidgetView(data: entry.widgetData)
        default:
            MediumWidgetView(data: entry.widgetData)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(spacing: 6) {
            Text("Remaining")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(formatTime(data.remainingSeconds))
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(remainingColor)

            Divider()

            if data.topApps.isEmpty {
                Text("No apps configured")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(data.topApps.prefix(3).enumerated()), id: \.offset) { _, app in
                        HStack(spacing: 4) {
                            Image(systemName: app.iconName ?? "app.fill")
                                .font(.system(size: 8))
                                .foregroundColor(app.configType == "reward" ? .green : .red)
                            Text(app.appName)
                                .font(.system(size: 9))
                                .lineLimit(1)
                            Spacer()
                            Text(formatRate(app.minutesPerMinute))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(app.configType == "reward" ? .green : .red)
                        }
                    }
                }
            }
        }
        .padding(12)
    }

    private var remainingColor: Color {
        if data.remainingSeconds > 3600 { return .green }
        if data.remainingSeconds > 1800 { return .orange }
        return .red
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 0) {
            // Left side: time remaining ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(progressValue))
                        .stroke(remainingColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text(formatTime(data.remainingSeconds))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(remainingColor)
                        Text("left")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                HStack(spacing: 8) {
                    VStack(spacing: 1) {
                        Text(formatTimeShort(data.totalEarned))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                        Text("earned")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 1) {
                        Text(formatTimeShort(data.totalPenalty))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.red)
                        Text("lost")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Right side: top 3 apps
            VStack(alignment: .leading, spacing: 6) {
                Text("Top Apps")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if data.topApps.isEmpty {
                    Spacer()
                    Text("No apps configured")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ForEach(Array(data.topApps.prefix(3).enumerated()), id: \.offset) { _, app in
                        HStack(spacing: 6) {
                            Image(systemName: app.iconName ?? "app.fill")
                                .font(.system(size: 14))
                                .foregroundColor(app.configType == "reward" ? .green : .red)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.appName)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Text(formatRate(app.minutesPerMinute))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(app.configType == "reward" ? .green : .red)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }

    private var progressValue: Double {
        let total = data.totalAllocated + data.totalEarned
        guard total > 0 else { return 0 }
        return min(1.0, max(0, data.remainingSeconds / total))
    }

    private var remainingColor: Color {
        if data.remainingSeconds > 3600 { return .green }
        if data.remainingSeconds > 1800 { return .orange }
        return .red
    }
}

// MARK: - Helpers

private func formatTime(_ seconds: TimeInterval) -> String {
    let totalSeconds = max(0, Int(seconds))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
}

private func formatTimeShort(_ seconds: TimeInterval) -> String {
    let totalSeconds = max(0, Int(seconds))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    if hours > 0 {
        return "\(hours)h\(minutes)m"
    }
    return "\(minutes)m"
}

private func formatRate(_ minutesPerMinute: Double) -> String {
    if minutesPerMinute > 0 {
        return "+\(String(format: "%.1f", minutesPerMinute))/min"
    }
    return "\(String(format: "%.1f", minutesPerMinute))/min"
}

// MARK: - Widget Definition

struct ScreenTimeWidget: Widget {
    let kind: String = "ScreenTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScreenTimeWidgetProvider()) { entry in
            ScreenTimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Screen Time")
        .description("See your remaining screen time and top apps at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Placeholder Data

extension WidgetData {
    static let placeholder = WidgetData(
        remainingSeconds: 5400,
        totalEarned: 1800,
        totalPenalty: 600,
        totalAllocated: 7200,
        totalUsed: 2400,
        topApps: [
            WidgetAppInfo(appName: "Health", iconName: "heart.fill", minutesPerMinute: 2.0, configType: "reward"),
            WidgetAppInfo(appName: "TikTok", iconName: "music.note.list", minutesPerMinute: -2.0, configType: "penalty"),
            WidgetAppInfo(appName: "Duolingo", iconName: "character.book.closed.fill", minutesPerMinute: 1.0, configType: "reward"),
        ],
        lastUpdated: Date()
    )

    init(
        remainingSeconds: TimeInterval = 0,
        totalEarned: TimeInterval = 0,
        totalPenalty: TimeInterval = 0,
        totalAllocated: TimeInterval = 7200,
        totalUsed: TimeInterval = 0,
        topApps: [WidgetAppInfo] = [],
        lastUpdated: Date = Date()
    ) {
        self.remainingSeconds = remainingSeconds
        self.totalEarned = totalEarned
        self.totalPenalty = totalPenalty
        self.totalAllocated = totalAllocated
        self.totalUsed = totalUsed
        self.topApps = topApps
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Previews

struct ScreenTimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScreenTimeWidgetEntryView(
                entry: ScreenTimeWidgetEntry(date: Date(), widgetData: .placeholder)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            ScreenTimeWidgetEntryView(
                entry: ScreenTimeWidgetEntry(date: Date(), widgetData: .placeholder)
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
