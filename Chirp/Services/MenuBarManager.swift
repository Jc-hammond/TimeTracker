//
//  MenuBarManager.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import AppKit
import SwiftData
import UserNotifications

@Observable
class MenuBarManager {
    static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var modelContext: ModelContext?
    private var sessionMonitorTimer: Timer?

    var isMenuBarEnabled = true

    // Computed property to always get the current active session from SwiftData
    var currentSession: FocusSession? {
        guard let modelContext = modelContext else { return nil }

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.endTime == nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try? modelContext.fetch(descriptor).first
    }

    private init() {}

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext

        guard isMenuBarEnabled else { return }

        // Prevent creating duplicate status items
        if statusItem != nil {
            // Already set up, just update the button
            updateStatusButton()
            return
        }

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

        // Save context to persist the changes
        try? modelContext?.save()

        updateStatusButton()
    }

    @objc private func resumeSession() {
        currentSession?.resume()

        // Save context to persist the changes
        try? modelContext?.save()

        updateStatusButton()
    }

    @objc private func stopSession() {
        currentSession?.complete()

        // Save context to persist the changes
        try? modelContext?.save()

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

        // Save context to persist the session
        try? modelContext.save()

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
        // Invalidate existing timer if any
        sessionMonitorTimer?.invalidate()

        // Update menu bar every second when session is active
        sessionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if let session = self.currentSession, session.isActive {
                self.updateStatusButton()

                // Check if session should end
                let elapsed = session.actualDuration
                if elapsed >= session.plannedDuration {
                    self.sendNotification(
                        title: "Focus Session Complete!",
                        body: "Your \(session.sessionType.rawValue) session is finished."
                    )
                }
            } else {
                // Update button even when no session
                self.updateStatusButton()
            }
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
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
        sessionMonitorTimer?.invalidate()
        sessionMonitorTimer = nil

        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
}
