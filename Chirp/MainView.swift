//
//  MainView.swift
//  Chirp
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
    @State private var notificationTokens: [NSObjectProtocol] = []

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
            if notificationTokens.isEmpty {
                setupNotificationObservers()
            }
        }
        .onDisappear {
            tearDownNotificationObservers()
        }
    }

    private func setupNotificationObservers() {
        let center = NotificationCenter.default

        let newProjectToken = center.addObserver(
            forName: .newProject,
            object: nil,
            queue: .main
        ) { _ in
            showingProjectSheet = true
        }

        let newEntryToken = center.addObserver(
            forName: .newEntry,
            object: nil,
            queue: .main
        ) { _ in
            showingManualEntry = true
        }

        let showDashboardToken = center.addObserver(
            forName: .showDashboard,
            object: nil,
            queue: .main
        ) { _ in
            selectedView = .dashboard
        }

        let showReportsToken = center.addObserver(
            forName: .showReports,
            object: nil,
            queue: .main
        ) { _ in
            selectedView = .reports
        }

        notificationTokens = [
            newProjectToken,
            newEntryToken,
            showDashboardToken,
            showReportsToken,
        ]
    }

    private func tearDownNotificationObservers() {
        guard !notificationTokens.isEmpty else { return }
        let center = NotificationCenter.default
        notificationTokens.forEach { center.removeObserver($0) }
        notificationTokens.removeAll()
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
        .navigationTitle("Chirp")
        .frame(minWidth: 240)
    }
}

struct ProjectRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerManager: TimerManager

    let project: Project

    @State private var showingEditSheet = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Button(action: startTimer) {
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

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.accent.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: { showingEditSheet = true }) {
                Label("Edit Project", systemImage: "pencil")
            }

            Button(action: startTimer) {
                Label("Start Timer", systemImage: "play.fill")
            }

            Divider()

            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("Delete Project", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
        .alert("Delete Project Permanently", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteProject()
            }
        } message: {
            let entryCount = project.timeEntries?.count ?? 0
            let totalDuration = project.timeEntries?.reduce(0) { $0 + $1.duration } ?? 0
            let totalEarnings = project.timeEntries?.reduce(0) { $0 + $1.earnings } ?? 0

            return Text("Are you sure you want to permanently delete '\(project.name)'?\n\nThis will delete \(entryCount) time \(entryCount == 1 ? "entry" : "entries") totaling \(totalDuration.formattedShort) and \(totalEarnings.formattedCurrency) in earnings.\n\nThis action cannot be undone.")
        }
    }

    private func startTimer() {
        timerManager.startTimer(for: project)
    }

    private func deleteProject() {
        modelContext.delete(project)
        do {
            try modelContext.save()
        } catch {
            LogManager.data.error("Failed to delete project \(project.id)", error: error)
        }
    }
}
