//
//  MenuBarManager.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import AppKit
import Combine
import SwiftData

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var timerManager: TimerManager
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(timerManager: TimerManager, modelContext: ModelContext) {
        self.timerManager = timerManager
        self.modelContext = modelContext
        super.init()

        setupMenuBar()
        observeTimerChanges()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateMenuBarButton()
        }

        updateMenu()
    }

    private func observeTimerChanges() {
        // Update menu bar when timer changes
        timerManager.$activeEntry
            .sink { [weak self] _ in
                self?.updateMenuBarButton()
                self?.updateMenu()
            }
            .store(in: &cancellables)

        timerManager.$elapsedTime
            .sink { [weak self] _ in
                self?.updateMenuBarButton()
            }
            .store(in: &cancellables)

        timerManager.$isPaused
            .sink { [weak self] _ in
                self?.updateMenuBarButton()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarButton() {
        guard let button = statusItem?.button else { return }

        if timerManager.isTracking {
            let icon = timerManager.isPaused ? "⏸" : "🟢"
            let time = timerManager.formattedTime
            button.title = "\(icon) \(time)"
        } else {
            button.title = "🕐"
        }
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Current timer section
        if timerManager.isTracking {
            if let project = timerManager.activeEntry?.project {
                let timerItem = NSMenuItem(
                    title: "⏱ \(project.displayName)",
                    action: nil,
                    keyEquivalent: ""
                )
                timerItem.isEnabled = false
                menu.addItem(timerItem)

                let timeItem = NSMenuItem(
                    title: "   \(timerManager.formattedTime)",
                    action: nil,
                    keyEquivalent: ""
                )
                timeItem.isEnabled = false
                menu.addItem(timeItem)

                if !timerManager.currentNotes.isEmpty {
                    let notesItem = NSMenuItem(
                        title: "   \(timerManager.currentNotes)",
                        action: nil,
                        keyEquivalent: ""
                    )
                    notesItem.isEnabled = false
                    menu.addItem(notesItem)
                }

                menu.addItem(NSMenuItem.separator())

                // Pause/Resume button
                if timerManager.isPaused {
                    menu.addItem(NSMenuItem(
                        title: "▶️ Resume",
                        action: #selector(resumeTimer),
                        keyEquivalent: ""
                    ))
                } else {
                    menu.addItem(NSMenuItem(
                        title: "⏸ Pause",
                        action: #selector(pauseTimer),
                        keyEquivalent: ""
                    ))
                }

                menu.addItem(NSMenuItem(
                    title: "■ Stop Timer",
                    action: #selector(stopTimer),
                    keyEquivalent: ""
                ))

                menu.addItem(NSMenuItem.separator())
            }
        } else {
            // Quick start section
            let quickStartItem = NSMenuItem(
                title: "Quick Start:",
                action: nil,
                keyEquivalent: ""
            )
            quickStartItem.isEnabled = false
            menu.addItem(quickStartItem)

            // Get recent projects
            let descriptor = FetchDescriptor<Project>(
                sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
            )
            if let projects = try? modelContext.fetch(descriptor) {
                let recentProjects = Array(projects.prefix(5).filter { !$0.isArchived })

                if recentProjects.isEmpty {
                    let noProjectsItem = NSMenuItem(
                        title: "   No recent projects",
                        action: nil,
                        keyEquivalent: ""
                    )
                    noProjectsItem.isEnabled = false
                    menu.addItem(noProjectsItem)
                } else {
                    for project in recentProjects {
                        let item = NSMenuItem(
                            title: "   \(project.displayName)",
                            action: #selector(startTimerForProject(_:)),
                            keyEquivalent: ""
                        )
                        item.representedObject = project
                        menu.addItem(item)
                    }
                }
            }

            menu.addItem(NSMenuItem.separator())
        }

        // App controls
        menu.addItem(NSMenuItem(
            title: "Show TimeTracker",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        // Set targets
        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc private func startTimerForProject(_ sender: NSMenuItem) {
        guard let project = sender.representedObject as? Project else { return }

        project.lastUsedAt = Date()
        timerManager.startTimer(for: project)

        try? modelContext.save()
    }

    @objc private func pauseTimer() {
        timerManager.pauseTimer()
    }

    @objc private func resumeTimer() {
        timerManager.resumeTimer()
    }

    @objc private func stopTimer() {
        if let entry = timerManager.stopTimer() {
            modelContext.insert(entry)
            try? modelContext.save()
        }
    }

    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Find and show the main window
        for window in NSApp.windows {
            if window.title.contains("TimeTracker") || window.contentView != nil {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    deinit {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
