//
//  MainView.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import AppKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerManager: TimerManager

    @State private var selectedView: NavigationItem = .dashboard
    @State private var showingProjectSheet = false
    @State private var showingManualEntry = false

    enum NavigationItem: Hashable {
        case dashboard
        case projects
        case reports
        case settings
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedView: $selectedView, showingProjectSheet: $showingProjectSheet)
        } detail: {
            Group {
                switch selectedView {
                case .dashboard:
                    DashboardView(showingProjectSheet: $showingProjectSheet)
                case .projects:
                    ProjectListView()
                case .reports:
                    ReportsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.secondaryBackground)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingProjectSheet) {
            NewProjectSheet()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualTimeEntrySheet()
        }
        .onAppear {
            // Setup menu bar
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.setDependencies(timerManager: timerManager, modelContext: modelContext)
            }

            // Setup keyboard shortcut handlers
            setupNotificationObservers()
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .newProject,
            object: nil,
            queue: .main
        ) { _ in
            showingProjectSheet = true
        }

        NotificationCenter.default.addObserver(
            forName: .newEntry,
            object: nil,
            queue: .main
        ) { _ in
            showingManualEntry = true
        }

        NotificationCenter.default.addObserver(
            forName: .showDashboard,
            object: nil,
            queue: .main
        ) { _ in
            selectedView = .dashboard
        }

        NotificationCenter.default.addObserver(
            forName: .showReports,
            object: nil,
            queue: .main
        ) { _ in
            selectedView = .reports
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.lastUsedAt, order: .reverse) private var recentProjects: [Project]
    @Query(sort: \Client.name) private var clients: [Client]

    @Binding var selectedView: MainView.NavigationItem
    @Binding var showingProjectSheet: Bool

    var body: some View {
        List(selection: $selectedView) {
            Section {
                NavigationLink(value: MainView.NavigationItem.dashboard) {
                    Label("Dashboard", systemImage: "clock.fill")
                }

                NavigationLink(value: MainView.NavigationItem.projects) {
                    Label("Projects", systemImage: "folder.fill")
                }

                NavigationLink(value: MainView.NavigationItem.reports) {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
            }

            Section("Recent Projects") {
                ForEach(recentProjects.prefix(5)) { project in
                    ProjectRowView(project: project)
                }
            }

            Section {
                Button(action: { showingProjectSheet = true }) {
                    Label("New Project", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("TimeTracker")
        .frame(minWidth: 240)
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.close) {
            if let client = project.client {
                Circle()
                    .fill(client.color)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                if let client = project.client {
                    Text(client.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
    }
}
