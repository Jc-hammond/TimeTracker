//
//  ChirpApp.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData

@main
struct ChirpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showStorageWarning = false

    static var isUsingInMemoryStorage = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusSession.self,
            TaskItem.self,
            DailyLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback to in-memory storage if persistent storage fails
            print("⚠️ Failed to create persistent ModelContainer: \(error)")
            print("⚠️ Falling back to in-memory storage. Data will not persist between app launches.")

            ChirpApp.isUsingInMemoryStorage = true

            let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfiguration])
            } catch {
                // This should rarely happen, but if it does, we need a last resort
                fatalError("Could not create even in-memory ModelContainer: \(error)")
            }
        }
    }()

    init() {
        // Check if we're using fallback storage
        if ChirpApp.isUsingInMemoryStorage {
            showStorageWarning = true
        }

        // Pass model context to app delegate and set up menu bar
        // No need for async - we're already on main thread and container is ready
        appDelegate.modelContext = sharedModelContainer.mainContext
        MenuBarManager.shared.setup(modelContext: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 450, maxWidth: .infinity, minHeight: 550, maxHeight: .infinity)
                .alert("Storage Warning", isPresented: $showStorageWarning) {
                    Button("OK") { }
                } message: {
                    Text("Failed to create persistent storage. Using temporary in-memory storage instead. Your data will not be saved between app launches.")
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentMinSize)
        .commands {
            // Add custom menu commands
            CommandGroup(after: .appInfo) {
                Button("Show Main Window") {
                    showMainWindow()
                }
                .keyboardShortcut("/", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button("New Focus Session") {
                    MenuBarManager.shared.startQuickSession(type: .deepWork)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }

        // Settings window
        Settings {
            SettingsView()
                .frame(width: 600, height: 700)
        }
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
