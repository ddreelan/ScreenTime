import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingAddRewardApp = false
    @State private var showingAddPenaltyApp = false
    @State private var showingEditApp: AppConfig?
    @State private var pendingPickedConfig: AppConfig?
    @State private var shortcutSetupConfig: AppConfig?

    private let sheetDismissalDelay: Double = 0.35

    private func pickedConfig(from app: InstalledAppInfo, configType: AppConfigType) -> AppConfig {
        let rate: Double = configType == .reward ? 1.0 : -1.0
        return AppConfig(
            bundleIdentifier: app.id,
            appName: app.name,
            appIcon: app.sfSymbol,
            configType: configType,
            minutesPerMinute: rate,
            isEnabled: true,
            category: app.category
        )
    }

    private func blankConfig(for configType: AppConfigType) -> AppConfig {
        let rate: Double = configType == .reward ? 1.0 : -1.0
        return AppConfig(
            bundleIdentifier: "",
            appName: "",
            appIcon: "app.fill",
            configType: configType,
            minutesPerMinute: rate,
            isEnabled: true,
            category: "Other"
        )
    }

    var body: some View {
        NavigationView {
            Form {
                // Daily Limit Section
                Section(header: Text("Daily Screen Time Limit")) {
                    HStack {
                        Text("Hours")
                        Spacer()
                        Stepper("\(Int(viewModel.dailyLimitHours))h", value: $viewModel.dailyLimitHours, in: 0...12)
                    }
                    HStack {
                        Text("Minutes")
                        Spacer()
                        Stepper("\(Int(viewModel.dailyLimitMinutes))m", value: $viewModel.dailyLimitMinutes, in: 0...55, step: 5)
                    }
                    Button("Save Daily Limit") {
                        viewModel.saveDailyLimit()
                    }
                    .foregroundColor(.blue)
                }

                // Reward Apps Section
                Section(header: Text("Reward Apps (Earn Time)")) {
                    ForEach(viewModel.rewardApps) { config in
                        VStack(spacing: 0) {
                            AppConfigRow(config: config) {
                                showingEditApp = config
                            } onToggle: {
                                viewModel.toggleAppEnabled(config)
                            }
                            Button {
                                shortcutSetupConfig = config
                            } label: {
                                Label("Set Up Shortcut", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 44)
                            .padding(.bottom, 6)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.removeAppConfig(at: offsets, from: .reward)
                    }
                    Button(action: { showingAddRewardApp = true }) {
                        Label("Add Reward App", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                // Penalty Apps Section
                Section(header: Text("Penalty Apps (Cost More Time)")) {
                    ForEach(viewModel.penaltyApps) { config in
                        VStack(spacing: 0) {
                            AppConfigRow(config: config) {
                                showingEditApp = config
                            } onToggle: {
                                viewModel.toggleAppEnabled(config)
                            }
                            Button {
                                shortcutSetupConfig = config
                            } label: {
                                Label("Set Up Shortcut", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 44)
                            .padding(.bottom, 6)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.removeAppConfig(at: offsets, from: .penalty)
                    }
                    Button(action: { showingAddPenaltyApp = true }) {
                        Label("Add Penalty App", systemImage: "plus.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                // Notifications Section
                Section(header: Text("Notifications")) {
                    NavigationLink("Break Reminders") {
                        BreakReminderSettingsView()
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddRewardApp) {
                AppPickerView(
                    configType: .reward,
                    alreadyConfiguredBundleIDs: Set(viewModel.rewardApps.map(\.bundleIdentifier))
                ) { pickedApp in
                    pendingPickedConfig = pickedConfig(from: pickedApp, configType: .reward)
                } onManual: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + sheetDismissalDelay) {
                        pendingPickedConfig = blankConfig(for: .reward)
                    }
                }
            }
            .sheet(isPresented: $showingAddPenaltyApp) {
                AppPickerView(
                    configType: .penalty,
                    alreadyConfiguredBundleIDs: Set(viewModel.penaltyApps.map(\.bundleIdentifier))
                ) { pickedApp in
                    pendingPickedConfig = pickedConfig(from: pickedApp, configType: .penalty)
                } onManual: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + sheetDismissalDelay) {
                        pendingPickedConfig = blankConfig(for: .penalty)
                    }
                }
            }
            .sheet(item: $pendingPickedConfig) { prefilled in
                AddEditAppConfigView(existingConfig: prefilled, isNewFromPicker: !prefilled.bundleIdentifier.isEmpty && !prefilled.appName.isEmpty) { savedConfig in
                    viewModel.addOrUpdateAppConfig(savedConfig)
                    pendingPickedConfig = nil
                }
            }
            .sheet(item: $showingEditApp) { config in
                AddEditAppConfigView(existingConfig: config) { updatedConfig in
                    viewModel.addOrUpdateAppConfig(updatedConfig)
                }
            }
            .sheet(item: $shortcutSetupConfig) { config in
                ShortcutSetupView(config: config)
            }
        }
    }
}

// MARK: - Shortcut Setup Sheet

struct ShortcutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    let config: AppConfig

    private var startURLString: String {
        "screentime://startApp?bundleID=\(config.bundleIdentifier)"
    }

    private var stopURLString: String {
        "screentime://stopApp"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    HStack(spacing: 14) {
                        Image(systemName: config.appIcon ?? "app.fill")
                            .font(.largeTitle)
                            .foregroundColor(config.configType == .reward ? .green : .red)
                            .frame(width: 56, height: 56)
                            .background((config.configType == .reward ? Color.green : Color.red).opacity(0.12))
                            .cornerRadius(14)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(config.appName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(config.configType == .reward ? "Reward App" : "Penalty App")
                                .font(.subheadline)
                                .foregroundColor(config.configType == .reward ? .green : .red)
                        }
                    }
                    .padding(.horizontal)

                    // What this does
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What this does")
                            .font(.headline)
                        Text("You'll create two Shortcuts automations — one that runs when \(config.appName) opens, and one when it closes. They automatically tell ScreenTime to start and stop tracking.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Step by step
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Setup Steps")
                            .font(.headline)
                            .padding(.horizontal)

                        StepView(number: 1, title: "Open Shortcuts", description: "Tap the button below to open the Shortcuts app.") {
                            Button {
                                if let url = URL(string: "shortcuts://") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }

                        StepView(number: 2, title: "Create the Open automation", description: "In Shortcuts: tap Automation → + → App → choose \(config.appName) → tick 'Is Opened' only → Next.") {
                            EmptyView()
                        }

                        StepView(number: 3, title: "Add the Open URL action", description: "Tap 'New Blank Automation' → search for 'Open URLs' → paste the URL below as the URL value.") {
                            URLCopyRow(label: "Start URL", urlString: startURLString)
                        }

                        StepView(number: 4, title: "Turn off Ask Before Running", description: "Toggle off 'Ask Before Running' and tap Done.") {
                            EmptyView()
                        }

                        StepView(number: 5, title: "Repeat for Close", description: "Create a second automation: App → \(config.appName) → tick 'Is Closed' only → Open URLs → paste the Stop URL below.") {
                            URLCopyRow(label: "Stop URL", urlString: stopURLString)
                        }
                    }

                    Divider()

                    // Test section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test It")
                            .font(.headline)
                            .padding(.horizontal)
                        Text("Tap the buttons below to test the URLs work. Your ScreenTime app should open and start/stop tracking.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button {
                                if let url = URL(string: startURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Test Start", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button {
                                if let url = URL(string: stopURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Test Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.gray)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Set Up Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Helper subviews

struct StepView<Content: View>: View {
    let number: Int
    let title: String
    let description: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            content
                .padding(.leading, 40)
        }
        .padding(.horizontal)
    }
}

struct URLCopyRow: View {
    let label: String
    let urlString: String
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            Text(urlString)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button {
                UIPasteboard.general.string = urlString
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundColor(copied ? .green : .blue)
            }
            .frame(width: 36, height: 36)
        }
    }
}

// MARK: - Existing subviews (unchanged)

struct AppConfigRow: View {
    let config: AppConfig
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let icon = config.appIcon {
                Image(systemName: icon)
                    .foregroundColor(config.configType == .reward ? .green : .red)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(config.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(config.effectDescription)
                    .font(.caption)
                    .foregroundColor(config.configType == .reward ? .green : .red)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}

struct AddEditAppConfigView: View {
    @Environment(\.dismiss) private var dismiss

    var existingConfig: AppConfig?
    var configType: AppConfigType
    var isNewFromPicker: Bool
    let onSave: (AppConfig) -> Void

    @State private var appName: String = ""
    @State private var bundleID: String = ""
    @State private var selectedIcon: String = "app.fill"
    @State private var minutesPerMinute: Double = 1.0
    @State private var isEnabled: Bool = true
    @State private var category: String = "Other"

    let icons = ["app.fill", "heart.fill", "figure.walk", "book.fill", "brain.head.profile",
                 "camera.fill", "play.rectangle.fill", "music.note", "gamecontroller.fill", "safari.fill"]

    init(configType: AppConfigType = .reward, existingConfig: AppConfig? = nil, isNewFromPicker: Bool = false, onSave: @escaping (AppConfig) -> Void) {
        self.existingConfig = existingConfig
        self.configType = existingConfig?.configType ?? configType
        self.isNewFromPicker = isNewFromPicker
        self.onSave = onSave

        if let config = existingConfig {
            _appName = State(initialValue: config.appName)
            _bundleID = State(initialValue: config.bundleIdentifier)
            _selectedIcon = State(initialValue: config.appIcon ?? "app.fill")
            _minutesPerMinute = State(initialValue: abs(config.minutesPerMinute))
            _isEnabled = State(initialValue: config.isEnabled)
            _category = State(initialValue: config.category)
        }
    }

    private var isEditingExistingApp: Bool {
        existingConfig?.appName.isEmpty == false && !isNewFromPicker
    }

    var body: some View {
        NavigationView {
            Form {
                if isNewFromPicker {
                    Section(header: Text("App Details")) {
                        HStack {
                            Image(systemName: selectedIcon)
                                .foregroundColor(configType == .reward ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(bundleID)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Section(header: Text("App Details")) {
                        TextField("App Name", text: $appName)
                        TextField("Bundle ID (e.g. com.apple.Health)", text: $bundleID)
                        TextField("Category", text: $category)
                    }

                    Section(header: Text("Icon")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue : Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onTapGesture { selectedIcon = icon }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Time Effect (minutes per minute used)")) {
                    HStack {
                        Text(configType == .reward ? "+\(String(format: "%.1f", minutesPerMinute))" : "-\(String(format: "%.1f", minutesPerMinute))")
                            .foregroundColor(configType == .reward ? .green : .red)
                            .font(.headline)
                            .frame(width: 60)
                        Slider(value: $minutesPerMinute, in: 0.1...5.0, step: 0.1)
                    }
                    Text("Each minute using this app \(configType == .reward ? "earns" : "costs") \(String(format: "%.1f", minutesPerMinute)) extra minute(s) of screen time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .navigationTitle(isEditingExistingApp ? "Edit App" : "Add App")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let effectValue = configType == .reward ? minutesPerMinute : -minutesPerMinute
                    let sanitizedName = appName
                        .lowercased()
                        .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-")).inverted)
                        .joined(separator: ".")
                    let generatedBundleID = "com.app.\(sanitizedName.isEmpty ? "app" : sanitizedName)"
                    let config = AppConfig(
                        id: existingConfig?.id ?? UUID(),
                        bundleIdentifier: bundleID.isEmpty ? generatedBundleID : bundleID,
                        appName: appName,
                        appIcon: selectedIcon,
                        configType: configType,
                        minutesPerMinute: effectValue,
                        isEnabled: isEnabled,
                        category: category
                    )
                    onSave(config)
                    dismiss()
                }
                .disabled(appName.isEmpty)
            )
        }
    }
}

struct BreakReminderSettingsView: View {
    @State private var breakInterval: Double = 60
    @State private var isEnabled: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Break Reminder")) {
                Toggle("Enable Break Reminders", isOn: $isEnabled)
                if isEnabled {
                    HStack {
                        Text("Remind every")
                        Spacer()
                        Text("\(Int(breakInterval)) minutes")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $breakInterval, in: 15...120, step: 15)
                    Button("Save") {
                        if isEnabled {
                            NotificationService.shared.scheduleBreakReminder(after: Int(breakInterval))
                        } else {
                            NotificationService.shared.cancelAllNotifications()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Break Reminders")
    }
}
