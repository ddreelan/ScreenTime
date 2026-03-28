import SwiftUI

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let configType: AppConfigType
    let alreadyConfiguredBundleIDs: Set<String>
    /// Called when the user picks an app — the caller shows the rate-setting sheet.
    let onSelect: (InstalledAppInfo) -> Void
    /// Called when the user taps "Add Manually".
    let onManual: () -> Void

    @State private var searchText = ""
    @State private var apps: [InstalledAppInfo] = []

    // MARK: - Filtered list

    private var filteredApps: [InstalledAppInfo] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
                              $0.category.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search apps…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // App list
                List(filteredApps) { app in
                    appRow(app)
                }
                .listStyle(.plain)

                // Manual-entry escape hatch
                Divider()
                Button(action: {
                    dismiss()
                    onManual()
                }) {
                    Label("Add Manually", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .navigationTitle(configType == .reward ? "Add Reward App" : "Add Penalty App")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .onAppear { apps = InstalledAppsService.shared.detectInstalledApps() }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func appRow(_ app: InstalledAppInfo) -> some View {
        let isConfigured = alreadyConfiguredBundleIDs.contains(app.id)
        HStack(spacing: 14) {
            Image(systemName: app.sfSymbol)
                .font(.title3)
                .foregroundColor(isConfigured ? .secondary : (configType == .reward ? .green : .red))
                .frame(width: 36, height: 36)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isConfigured ? .secondary : .primary)
                Text(app.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isConfigured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isConfigured else { return }
            dismiss()
            onSelect(app)
        }
    }
}
