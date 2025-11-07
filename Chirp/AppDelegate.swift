//
//  AppDelegate.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Cocoa
import SwiftUI
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContext: ModelContext?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        requestNotificationPermissions()

        // Set up menu bar if model context is available
        if let modelContext = modelContext {
            MenuBarManager.shared.setup(modelContext: modelContext)
        }

        // Set up global shortcuts
        GlobalShortcutManager.shared.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        MenuBarManager.shared.cleanup()
        GlobalShortcutManager.shared.cleanup()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show main window when clicking dock icon
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    // Don't terminate when last window closes (for menu bar mode)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in menu bar
    }

    private func requestNotificationPermissions() {
        let center = NSUserNotificationCenter.default
        center.delegate = self
    }
}

// MARK: - Notification Delegate
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        // Show main window when notification is clicked
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
