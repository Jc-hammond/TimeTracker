//
//  ChirpApp.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import AppKit
import Combine

@main
struct ChirpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    @StateObject private var appBootstrapper = AppBootstrapper()

    private let sharedModelContainer: ModelContainer?
    private static let chirpSchema = Schema([
        Client.self,
        Project.self,
        TimeEntry.self,
        UserSettings.self,
    ])

    init() {
        do {
            sharedModelContainer = try Self.makeModelContainer()
        } catch {
            LogManager.app.error("Failed to create persistent ModelContainer", error: error)
            do {
                sharedModelContainer = try Self.makeModelContainer(isInMemoryOnly: true)
                LogManager.app.warning("Using in-memory data store fallback. Changes will not be persisted.")
            } catch {
                sharedModelContainer = nil
                LogManager.app.fault("Unable to create even the in-memory ModelContainer: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                MainView()
                    .environmentObject(timerManager)
                    .modelContainer(container)
                    .onAppear {
                        performInitialSetup(using: container)
                    }
            } else {
                DataStoreErrorView()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: sharedModelContainer != nil ? 520 : 420, height: sharedModelContainer != nil ? 680 : 280)
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

    @MainActor
    private func performInitialSetup(using container: ModelContainer) {
        guard !appBootstrapper.hasPerformedSetup else {
            return
        }

        LogManager.app.info("Setting up dependencies and menu bar")

        appBootstrapper.hasPerformedSetup = true

        appDelegate.timerManager = timerManager
        appDelegate.modelContext = container.mainContext
        appDelegate.setupMenuBar()

        timerManager.configure(with: container.mainContext)

        SampleDataManager.createSampleData(context: container.mainContext)
        timerManager.restoreTimerState()
    }

    private static func makeModelContainer(isInMemoryOnly: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: chirpSchema, isStoredInMemoryOnly: isInMemoryOnly)
        return try ModelContainer(for: chirpSchema, configurations: [configuration])
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
        LogManager.app.info("Application did finish launching")
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
        LogManager.app.debug("setupMenuBar called - timerManager: \(timerManager != nil), modelContext: \(modelContext != nil), menuBarManager exists: \(menuBarManager != nil)")

        guard let timerManager = timerManager,
              let modelContext = modelContext else {
            LogManager.app.warning("Missing dependencies, cannot create menu bar")
            return
        }

        guard menuBarManager == nil else {
            LogManager.app.info("Menu bar already initialized, skipping")
            return
        }

        LogManager.app.info("Creating MenuBarManager")
        menuBarManager = MenuBarManager(timerManager: timerManager, modelContext: modelContext)
        LogManager.app.info("MenuBarManager created successfully")
    }
}

// MARK: - App Bootstrap Support
private final class AppBootstrapper: ObservableObject {
    @Published var hasPerformedSetup = false
}

private struct DataStoreErrorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Chirp Can’t Access Its Data")
                .font(.title3).bold()
            Text("Please quit and relaunch the app. If the issue persists, contact support.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Quit Chirp") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.secondaryBackground)
    }
}
