//
//  ChirpApp.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct ChirpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Client.self,
            Project.self,
            TimeEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Configure app to stay running with windows closed
//        NSApp.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(timerManager)
                .onAppear {
                    print("🔧 ChirpApp: Setting up dependencies and menu bar")

                    // Initialize app delegate dependencies
                    appDelegate.timerManager = timerManager
                    appDelegate.modelContext = sharedModelContainer.mainContext
                    appDelegate.setupMenuBar()

                    timerManager.configure(with: sharedModelContainer.mainContext)

                    // Seed sample data on first launch
                    Task { @MainActor in
                        SampleDataManager.createSampleData(context: sharedModelContainer.mainContext)

                        // Restore timer state after data is loaded
                        timerManager.restoreTimerState()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project...") {
                    NotificationCenter.default.post(name: .newProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Time Entry...") {
                    NotificationCenter.default.post(name: .newEntry, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])
            }

            CommandGroup(after: .sidebar) {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .showDashboard, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Reports") {
                    NotificationCenter.default.post(name: .showReports, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newProject = Notification.Name("newProject")
    static let newEntry = Notification.Name("newEntry")
    static let showDashboard = Notification.Name("showDashboard")
    static let showReports = Notification.Name("showReports")
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var timerManager: TimerManager?
    var modelContext: ModelContext?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: Application did finish launching")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Show window when dock icon is clicked and no windows are visible
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func setupMenuBar() {
        print("🔧 AppDelegate: setupMenuBar called")
        print("   - timerManager: \(timerManager != nil ? "✅" : "❌")")
        print("   - modelContext: \(modelContext != nil ? "✅" : "❌")")
        print("   - menuBarManager already exists: \(menuBarManager != nil ? "✅" : "❌")")

        guard let timerManager = timerManager,
              let modelContext = modelContext else {
            print("⚠️ AppDelegate: Missing dependencies, cannot create menu bar")
            return
        }

        guard menuBarManager == nil else {
            print("ℹ️ AppDelegate: Menu bar already initialized, skipping")
            return
        }

        print("✨ AppDelegate: Creating MenuBarManager")
        menuBarManager = MenuBarManager(timerManager: timerManager, modelContext: modelContext)
        print("✅ AppDelegate: MenuBarManager created successfully")
    }
}
