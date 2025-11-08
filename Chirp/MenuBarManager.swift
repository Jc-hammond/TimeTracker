//
//  MenuBarManager.swift
//  Chirp
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
    private var isUpdatingMenu = false

    init(timerManager: TimerManager, modelContext: ModelContext) {
        LogManager.menu.info("Initializing MenuBarManager")
        self.timerManager = timerManager
        self.modelContext = modelContext
        super.init()

        setupMenuBar()
        observeTimerChanges()
        LogManager.menu.info("MenuBarManager initialization complete")
    }

    private func setupMenuBar() {
        LogManager.menu.debug("Setting up menu bar")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusItem = statusItem {
            LogManager.menu.info("Status item created successfully")

            if statusItem.button != nil {
                updateMenuBarButton()
            } else {
                LogManager.menu.warning("Status item button is nil")
            }
        } else {
            LogManager.menu.error("Failed to create status item")
        }

        updateMenu()
        LogManager.menu.info("Menu bar setup complete")
    }

    private func observeTimerChanges() {
        // Observe activeEntry changes - rebuild entire menu (debounced to prevent duplicates)
        timerManager.$activeEntry
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateMenuBarButton()
                    self?.updateMenu()
                }
            }
            .store(in: &cancellables)

        // Observe time/pause changes - update button and rebuild menu for pause state
        Publishers.CombineLatest(
            timerManager.$elapsedTime,
            timerManager.$isPaused
        )
        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenuBarButton()
                self?.updateMenu()  // Rebuild menu to update pause/resume button text
            }
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
        // Prevent concurrent menu updates
        guard !isUpdatingMenu else { return }
        isUpdatingMenu = true
        defer { isUpdatingMenu = false }

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

                // Show start time
                if let startTime = timerManager.activeEntry?.startTime {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.dateStyle = .none
                    let formattedStartTime = formatter.string(from: startTime)

                    let timeItem = NSMenuItem(
                        title: "   Started at \(formattedStartTime)",
                        action: nil,
                        keyEquivalent: ""
                    )
                    timeItem.isEnabled = false
                    menu.addItem(timeItem)
                }

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
            do {
                let projects = try modelContext.fetch(descriptor)
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
            } catch {
                LogManager.menu.error("Failed to fetch recent projects", error: error)
                let errorItem = NSMenuItem(
                    title: "   Unable to load projects",
                    action: nil,
                    keyEquivalent: ""
                )
                errorItem.isEnabled = false
                menu.addItem(errorItem)
            }

            menu.addItem(NSMenuItem.separator())
        }

        // App controls
        menu.addItem(NSMenuItem(
            title: "Show Chirp",
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

        timerManager.startTimer(for: project)
    }

    @objc private func pauseTimer() {
        timerManager.pauseTimer()
    }

    @objc private func resumeTimer() {
        timerManager.resumeTimer()
    }

    @objc private func stopTimer() {
        _ = timerManager.stopTimer()
    }

    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Find and show the main window
        for window in NSApp.windows {
            if window.title.contains("Chirp") || window.contentView != nil {
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
