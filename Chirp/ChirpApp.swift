//
//  TimeTrackerApp.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct TimeTrackerApp: App {
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
        NSApp.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(timerManager)
                .onAppear {
                    // Initialize app delegate dependencies
                    appDelegate.timerManager = timerManager
                    appDelegate.modelContext = sharedModelContainer.mainContext

                    // Seed sample data on first launch
                    Task { @MainActor in
                        SampleDataManager.createSampleData(context: sharedModelContainer.mainContext)

                        // Restore timer state after data is loaded
                        timerManager.restoreTimerState(modelContext: sharedModelContainer.mainContext)
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
        // Setup will happen when dependencies are injected from TimeTrackerApp
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

    // Called when dependencies are set
    func setupMenuBar() {
        guard let timerManager = timerManager,
              let modelContext = modelContext,
              menuBarManager == nil else { return }

        menuBarManager = MenuBarManager(timerManager: timerManager, modelContext: modelContext)
    }
}

// Extension to setup menu bar once dependencies are ready
extension AppDelegate {
    func setDependencies(timerManager: TimerManager, modelContext: ModelContext) {
        self.timerManager = timerManager
        self.modelContext = modelContext
        setupMenuBar()
    }
}
