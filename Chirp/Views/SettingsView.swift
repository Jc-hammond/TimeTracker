//
//  SettingsView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSounds") private var enableSounds = true
    @AppStorage("defaultSessionType") private var defaultSessionType = SessionType.deepWork.rawValue
    @AppStorage("breakReminderEnabled") private var breakReminderEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Customize your Chirp experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Appearance Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        SettingsToggleRow(
                            icon: "menubar.rectangle",
                            title: "Show Menu Bar Icon",
                            description: "Display Chirp icon in the menu bar for quick access",
                            isOn: $showMenuBarIcon
                        )

                        SettingsToggleRow(
                            icon: "dock.rectangle",
                            title: "Show in Dock",
                            description: "Display Chirp icon in the Dock",
                            isOn: $showInDock
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Startup Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Startup")
                        .font(.title2)
                        .fontWeight(.semibold)

                    SettingsToggleRow(
                        icon: "power",
                        title: "Launch at Login",
                        description: "Automatically start Chirp when you log in to your Mac",
                        isOn: $launchAtLogin
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Notifications Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        SettingsToggleRow(
                            icon: "bell.fill",
                            title: "Enable Notifications",
                            description: "Show notifications for session starts, breaks, and completions",
                            isOn: $enableNotifications
                        )

                        SettingsToggleRow(
                            icon: "speaker.wave.2.fill",
                            title: "Enable Sounds",
                            description: "Play sounds with notifications",
                            isOn: $enableSounds
                        )

                        SettingsToggleRow(
                            icon: "bell.badge.fill",
                            title: "Break Reminders",
                            description: "Get reminded to take breaks between sessions",
                            isOn: $breakReminderEnabled
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Session Defaults Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Defaults")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Session Type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Default Session Type", selection: $defaultSessionType) {
                            ForEach(SessionType.allCases) { type in
                                Text(type.rawValue).tag(type.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Keyboard Shortcuts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Keyboard Shortcuts")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        ShortcutRow(
                            action: "Start Focus Session",
                            shortcut: "⌘⇧F"
                        )

                        ShortcutRow(
                            action: "Pause/Resume Session",
                            shortcut: "⌘⇧P"
                        )

                        ShortcutRow(
                            action: "Stop Session",
                            shortcut: "⌘⇧S"
                        )

                        ShortcutRow(
                            action: "Quick Add Task",
                            shortcut: "⌘T"
                        )

                        ShortcutRow(
                            action: "Toggle Main Window",
                            shortcut: "⌘/"
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Data Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        Button {
                            exportData()
                        } label: {
                            Label("Export All Data", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            clearAllData()
                        } label: {
                            Label("Clear All Data", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // About Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("1.0.0")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Build")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("2025.11.07")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Chirp - Indie Dev Companion")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Built with ❤️ for indie hackers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .onChange(of: showMenuBarIcon) { _, newValue in
            MenuBarManager.shared.isMenuBarEnabled = newValue
            if newValue {
                // Re-setup menu bar
                // Would need model context access here
            }
        }
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "chirp-export-\(Date().ISO8601Format()).json"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Export logic would go here
                print("Export to: \(url)")
            }
        }
    }

    private func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "Clear All Data?"
        alert.informativeText = "This will permanently delete all your sessions, tasks, and logs. This action cannot be undone."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear All Data")

        if alert.runModal() == .alertSecondButtonReturn {
            // Clear data logic would go here
            print("Clearing all data...")
        }
    }
}

// MARK: - Supporting Views

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
                .font(.body)

            Spacer()

            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView()
}
