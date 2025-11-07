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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Pass model context to app delegate after container is created
        DispatchQueue.main.async { [self] in
            appDelegate.modelContext = sharedModelContainer.mainContext
            MenuBarManager.shared.setup(modelContext: sharedModelContainer.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    // Additional setup after view appears
                    setupWindow()
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
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

    private func setupWindow() {
        // Configure main window
        if let window = NSApp.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
        }
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
