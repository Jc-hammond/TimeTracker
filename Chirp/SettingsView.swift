//
//  SettingsView.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]

    @State private var userName: String = ""
    @State private var currencyCode: String = "USD"
    @State private var defaultHourlyRate: String = ""
    @State private var showEarningsInMenuBar: Bool = false
    @State private var roundTimeToNearestMinute: Int = 0

    private var settings: UserSettings? {
        settingsQuery.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.accent)

                    Text("Settings")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Spacer()
                }
                .padding(.bottom, DesignSystem.Spacing.comfortable)

                // Personal Settings
                SettingsSectionView(title: "Personal") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
                        Text("Your Name")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)

                        TextField("Enter your name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: userName) { _, newValue in
                                saveSettings()
                            }

                        Text("Used in the dashboard greeting")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }

                // Financial Settings
                SettingsSectionView(title: "Financial") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
                        // Currency Selection
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                            Text("Currency")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.secondaryText)

                            Picker("Currency", selection: $currencyCode) {
                                ForEach(UserSettings.supportedCurrencies, id: \.code) { currency in
                                    Text("\(currency.symbol) \(currency.name)").tag(currency.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: currencyCode) { _, _ in
                                saveSettings()
                                // Update DesignSystem currency
                                if let symbol = UserSettings.supportedCurrencies.first(where: { $0.code == currencyCode })?.symbol {
                                    DesignSystem.updateCurrency(code: currencyCode, symbol: symbol)
                                }
                            }
                        }

                        // Default Hourly Rate
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                            Text("Default Hourly Rate")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.secondaryText)

                            TextField("0.00", text: $defaultHourlyRate)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: defaultHourlyRate) { _, _ in
                                    saveSettings()
                                }

                            Text("Default rate for new projects")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }

                // Timer Settings
                SettingsSectionView(title: "Timer") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
                        // Round Time
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                            Text("Round Time To")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.secondaryText)

                            Picker("Round Time", selection: $roundTimeToNearestMinute) {
                                Text("No rounding").tag(0)
                                Text("1 minute").tag(1)
                                Text("5 minutes").tag(5)
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                            }
                            .pickerStyle(.menu)
                            .onChange(of: roundTimeToNearestMinute) { _, _ in
                                saveSettings()
                            }

                            Text("Automatically round tracked time entries")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }

                        // Menu Bar Options
                        Toggle("Show earnings in menu bar", isOn: $showEarningsInMenuBar)
                            .font(DesignSystem.Typography.callout)
                            .onChange(of: showEarningsInMenuBar) { _, _ in
                                saveSettings()
                            }
                    }
                }

                // Data Management
                SettingsSectionView(title: "Data Management") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                            Text("Backup & Restore")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.secondaryText)

                            Text("Create a backup of all your data or restore from a previous backup")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }

                        HStack(spacing: DesignSystem.Spacing.comfortable) {
                            Button(action: createBackup) {
                                Label("Create Backup", systemImage: "arrow.down.doc")
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: restoreBackup) {
                                Label("Restore Backup", systemImage: "arrow.up.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // About Section
                SettingsSectionView(title: "About") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                        HStack {
                            Text("Version")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .font(DesignSystem.Typography.callout)

                        Divider()

                        HStack {
                            Text("Build")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .font(DesignSystem.Typography.callout)
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.dramatic)
            }
            .padding(DesignSystem.Spacing.comfortable)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.secondaryBackground)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        let userSettings = UserSettings.getOrCreate(context: modelContext)

        // If no user name is set, try to get system username
        if userSettings.userName.isEmpty {
            userSettings.userName = NSFullUserName().components(separatedBy: " ").first ?? ""
        }

        userName = userSettings.userName
        currencyCode = userSettings.currencyCode
        defaultHourlyRate = userSettings.defaultHourlyRate > 0 ? String(format: "%.2f", userSettings.defaultHourlyRate) : ""
        showEarningsInMenuBar = userSettings.showEarningsInMenuBar
        roundTimeToNearestMinute = userSettings.roundTimeToNearestMinute

        // Update DesignSystem currency on load
        if let symbol = UserSettings.supportedCurrencies.first(where: { $0.code == currencyCode })?.symbol {
            DesignSystem.updateCurrency(code: currencyCode, symbol: symbol)
        }
    }

    private func saveSettings() {
        let userSettings = UserSettings.getOrCreate(context: modelContext)

        userSettings.userName = userName
        userSettings.currencyCode = currencyCode
        userSettings.defaultHourlyRate = Double(defaultHourlyRate) ?? 0.0
        userSettings.showEarningsInMenuBar = showEarningsInMenuBar
        userSettings.roundTimeToNearestMinute = roundTimeToNearestMinute
        userSettings.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            LogManager.data.error("Failed to save user settings", error: error)
        }
    }

    // MARK: - Backup/Restore Functions

    private func createBackup() {
        if let url = ExportManager.createBackup(context: modelContext) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func restoreBackup() {
        let openPanel = NSOpenPanel()
        openPanel.message = "Select a Chirp backup file to restore"
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        guard openPanel.runModal() == .OK, let url = openPanel.url else {
            return
        }

        // Confirm restoration
        let alert = NSAlert()
        alert.messageText = "Restore Backup?"
        alert.informativeText = "This will import all data from the backup. Existing data will be preserved unless there are conflicts."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Restore")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try ExportManager.restoreBackup(from: url, context: modelContext)

            let successAlert = NSAlert()
            successAlert.messageText = "Backup Restored"
            successAlert.informativeText = "Your data has been successfully restored from the backup."
            successAlert.alertStyle = .informational
            successAlert.runModal()

            // Reload settings
            loadSettings()
        } catch {
            LogManager.data.error("Failed to restore backup", error: error)

            let errorAlert = NSAlert()
            errorAlert.messageText = "Restore Failed"
            errorAlert.informativeText = "Failed to restore backup: \(error.localizedDescription)"
            errorAlert.alertStyle = .critical
            errorAlert.runModal()
        }
    }
}

// MARK: - Settings Section View
struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .padding(.bottom, DesignSystem.Spacing.close)

            content()
                .padding(DesignSystem.Spacing.comfortable)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }
}
