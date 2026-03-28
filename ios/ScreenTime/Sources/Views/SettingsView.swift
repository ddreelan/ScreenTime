import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingAddRewardApp = false
    @State private var showingAddPenaltyApp = false
    @State private var showingEditApp: AppConfig?
    /// Holds a pre-populated config selected from AppPickerView, waiting for rate setup.
    @State private var pendingPickedConfig: AppConfig?

    /// Delay between sheet dismissal and presenting the next sheet.
    private let sheetDismissalDelay: Double = 0.35

    /// Creates an AppConfig pre-filled from a picker selection.
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

    /// Creates a blank AppConfig for manual entry.
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
                        AppConfigRow(config: config) {
                            showingEditApp = config
                        } onToggle: {
                            viewModel.toggleAppEnabled(config)
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
                        AppConfigRow(config: config) {
                            showingEditApp = config
                        } onToggle: {
                            viewModel.toggleAppEnabled(config)
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
            // Reward app picker
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
            // Penalty app picker
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
            // Rate-setting sheet (after picking from list, or manual entry)
            .sheet(item: $pendingPickedConfig) { prefilled in
                AddEditAppConfigView(existingConfig: prefilled, isNewFromPicker: !prefilled.bundleIdentifier.isEmpty && !prefilled.appName.isEmpty) { savedConfig in
                    viewModel.addOrUpdateAppConfig(savedConfig)
                    pendingPickedConfig = nil
                }
            }
            // Edit existing app
            .sheet(item: $showingEditApp) { config in
                AddEditAppConfigView(existingConfig: config) { updatedConfig in
                    viewModel.addOrUpdateAppConfig(updatedConfig)
                }
            }
        }
    }
}

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
    /// When true the app details (name, bundle ID, icon) were pre-filled from AppPickerView
    /// and should be shown read-only instead of editable.
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
                // App Details — editable for manual entry, read-only when pre-filled from picker
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
                    // Sanitize bundle ID: keep only alphanumeric, hyphens, and periods
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
