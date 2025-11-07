//
//  AppDelegate.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Cocoa
import SwiftUI
import SwiftData
import UserNotifications

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
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - Notification Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        return [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Show main window when notification is clicked
        await MainActor.run {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
