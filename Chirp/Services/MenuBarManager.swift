//
//  MenuBarManager.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import AppKit
import SwiftData

@Observable
class MenuBarManager {
    static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var modelContext: ModelContext?

    var currentSession: FocusSession?
    var isMenuBarEnabled = true

    private init() {}

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext

        guard isMenuBarEnabled else { return }

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateStatusButton()
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 400)
        popover.behavior = .transient
        self.popover = popover

        // Start monitoring sessions
        startSessionMonitoring()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }

        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let modelContext = modelContext {
                    popover.contentViewController = NSHostingController(
                        rootView: MenuBarPopoverView(manager: self)
                            .modelContainer(for: [FocusSession.self, TaskItem.self, DailyLog.self])
                            .environment(\.modelContext, modelContext)
                    )
                }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        if let session = currentSession {
            if session.isPaused {
                menu.addItem(withTitle: "Resume Session", action: #selector(resumeSession), keyEquivalent: "")
            } else {
                menu.addItem(withTitle: "Pause Session", action: #selector(pauseSession), keyEquivalent: "")
            }
            menu.addItem(withTitle: "Stop Session", action: #selector(stopSession), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(withTitle: "Start Deep Work", action: #selector(startDeepWork), keyEquivalent: "")
        menu.addItem(withTitle: "Start Sprint", action: #selector(startSprint), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Chirp", action: #selector(quitApp), keyEquivalent: "q")

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        // Remove menu after it's shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    @objc private func startDeepWork() {
        startQuickSession(type: .deepWork)
    }

    @objc private func startSprint() {
        startQuickSession(type: .sprint)
    }

    @objc private func pauseSession() {
        currentSession?.pause()
        updateStatusButton()
    }

    @objc private func resumeSession() {
        currentSession?.resume()
        updateStatusButton()
    }

    @objc private func stopSession() {
        currentSession?.complete()
        currentSession = nil
        updateStatusButton()
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Find and show main window
        for window in NSApp.windows {
            if window.contentViewController != nil {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func startQuickSession(type: SessionType, category: TaskCategory = .building) {
        guard let modelContext = modelContext else { return }

        let session = FocusSession(
            sessionType: type,
            category: category
        )
        modelContext.insert(session)
        currentSession = session
        updateStatusButton()

        // Show notification
        sendNotification(
            title: "Focus Session Started",
            body: "\(type.rawValue) - \(category.rawValue)"
        )
    }

    private func updateStatusButton() {
        guard let button = statusItem?.button else { return }

        if let session = currentSession, session.isActive {
            let timeRemaining = session.plannedDuration - session.actualDuration
            let minutes = Int(max(timeRemaining, 0)) / 60

            if session.isPaused {
                button.title = "⏸️ \(minutes)m"
            } else {
                button.title = "⏱️ \(minutes)m"
            }

            // Update tooltip
            button.toolTip = """
            \(session.category.rawValue) - \(session.sessionType.rawValue)
            \(formatDuration(session.actualDuration)) elapsed
            """
        } else {
            button.title = "⚡️"
            button.toolTip = "Chirp - Start a focus session"
        }
    }

    private func startSessionMonitoring() {
        // Update menu bar every second when session is active
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.currentSession else { return }

            if session.isActive {
                self.updateStatusButton()

                // Check if session should end
                let elapsed = session.actualDuration
                if elapsed >= session.plannedDuration {
                    self.sendNotification(
                        title: "Focus Session Complete!",
                        body: "Your \(session.sessionType.rawValue) session is finished."
                    )
                }
            }
        }
    }

    private func sendNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    func cleanup() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
