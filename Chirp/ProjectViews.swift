//
//  ProjectViews.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData

// MARK: - Project Picker Sheet
struct ProjectPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerManager: TimerManager
    @Query(sort: \Project.lastUsedAt, order: .reverse) private var projects: [Project]

    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var notes = ""
    @State private var showingNewProject = false

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects.filter { !$0.isArchived }
        }
        return projects.filter { project in
            !project.isArchived &&
            (project.name.localizedCaseInsensitiveContains(searchText) ||
             project.client?.name.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.tertiaryText)

                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                }
                .padding(DesignSystem.Spacing.comfortable)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .padding()

                // Notes field
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
                    Text("Add notes (optional)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    TextField("What are you working on?", text: $notes)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .padding(DesignSystem.Spacing.comfortable)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding(.horizontal)

                // Project list
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.close) {
                        ForEach(filteredProjects) { project in
                            ProjectPickerRow(project: project) {
                                startTimer(for: project)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet()
        }
    }

    private func startTimer(for project: Project) {
        project.lastUsedAt = Date()
        timerManager.startTimer(for: project, notes: notes)
        isPresented = false
    }
}

struct ProjectPickerRow: View {
    let project: Project
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.comfortable) {
                if let client = project.client {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(client.color)
                        .frame(width: 4, height: 48)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(DesignSystem.Typography.body.weight(.medium))
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    HStack(spacing: DesignSystem.Spacing.close) {
                        if let client = project.client {
                            Text(client.name)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)

                            Text("•")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }

                        Text(project.hourlyRate.formattedCurrency + "/hr")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding(DesignSystem.Spacing.comfortable)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var projectName = ""
    @State private var hourlyRate = ""
    @State private var selectedClient: Client?
    @State private var showingNewClient = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project name", text: $projectName)
                        .font(DesignSystem.Typography.body)

                    TextField("Hourly rate", text: $hourlyRate)
                        .font(DesignSystem.Typography.body)
                }

                Section("Client") {
                    Picker("Client", selection: $selectedClient) {
                        Text("No client").tag(nil as Client?)
                        ForEach(clients) { client in
                            HStack {
                                Circle()
                                    .fill(client.color)
                                    .frame(width: 12, height: 12)
                                Text(client.name)
                            }
                            .tag(client as Client?)
                        }
                    }

                    Button("New Client") {
                        showingNewClient = true
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(projectName.isEmpty || hourlyRate.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingNewClient) {
            NewClientSheet(onClientCreated: { client in
                selectedClient = client
            })
        }
    }

    private func createProject() {
        guard let rate = Double(hourlyRate) else { return }

        let project = Project(name: projectName, hourlyRate: rate, client: selectedClient)
        modelContext.insert(project)

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - New Client Sheet
struct NewClientSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var clientName = ""
    @State private var defaultRate = ""
    @State private var selectedColorHex = "FF6B35"

    let onClientCreated: (Client) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Client name", text: $clientName)
                        .font(DesignSystem.Typography.body)

                    TextField("Default hourly rate", text: $defaultRate)
                        .font(DesignSystem.Typography.body)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: DesignSystem.Spacing.comfortable) {
                        ForEach(DesignSystem.Colors.clientColors, id: \.self) { colorHex in
                            Button(action: { selectedColorHex = colorHex }) {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                    )
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createClient()
                    }
                    .disabled(clientName.isEmpty)
                }
            }
        }
    }

    private func createClient() {
        let rate = Double(defaultRate) ?? 0

        let client = Client(name: clientName, colorHex: selectedColorHex, defaultHourlyRate: rate)
        modelContext.insert(client)

        try? modelContext.save()
        onClientCreated(client)
        dismiss()
    }
}

// MARK: - Project List View
struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var showingNewProject = false
    @State private var searchText = ""

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects.filter { !$0.isArchived }
        }
        return projects.filter { project in
            !project.isArchived &&
            (project.name.localizedCaseInsensitiveContains(searchText) ||
             project.client?.name.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(filteredProjects) { project in
                    ProjectListRow(project: project)
                }
                .onDelete(perform: deleteProjects)
            }
            .searchable(text: $searchText, prompt: "Search projects")
        }
        .navigationTitle("Projects")
        .toolbar {
            Button(action: { showingNewProject = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet()
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            projects[index].isArchived = true
        }
    }
}

struct ProjectListRow: View {
    let project: Project

    @State private var showingEditSheet = false

    var body: some View {
        Button(action: { showingEditSheet = true }) {
            HStack {
                if let client = project.client {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(client.color)
                        .frame(width: 4, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(DesignSystem.Typography.body.weight(.medium))

                    if let client = project.client {
                        Text(client.name)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }

                Spacer()

                Text(project.hourlyRate.formattedCurrency + "/hr")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
    }
}

// MARK: - Edit Project Sheet
struct EditProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Client.name) private var clients: [Client]

    let project: Project

    @State private var projectName: String
    @State private var hourlyRate: String
    @State private var selectedClient: Client?
    @State private var showingNewClient = false
    @State private var showDeleteConfirmation = false

    init(project: Project) {
        self.project = project
        _projectName = State(initialValue: project.name)
        _hourlyRate = State(initialValue: String(format: "%.2f", project.hourlyRate))
        _selectedClient = State(initialValue: project.client)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project name", text: $projectName)
                        .font(DesignSystem.Typography.body)

                    TextField("Hourly rate", text: $hourlyRate)
                        .font(DesignSystem.Typography.body)
                }

                Section("Client") {
                    Picker("Client", selection: $selectedClient) {
                        Text("No client").tag(nil as Client?)
                        ForEach(clients) { client in
                            HStack {
                                Circle()
                                    .fill(client.color)
                                    .frame(width: 12, height: 12)
                                Text(client.name)
                            }
                            .tag(client as Client?)
                        }
                    }

                    Button("New Client") {
                        showingNewClient = true
                    }
                }

                Section {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Archive Project", systemImage: "archivebox")
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Archive Project", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    archiveProject()
                }
            } message: {
                Text("Are you sure you want to archive '\(project.name)'? You can still see archived projects and their time entries, but they won't appear in active lists.")
            }
        }
        .sheet(isPresented: $showingNewClient) {
            NewClientSheet(onClientCreated: { client in
                selectedClient = client
            })
        }
    }

    private var isValid: Bool {
        !projectName.isEmpty && !hourlyRate.isEmpty && Double(hourlyRate) != nil
    }

    private func saveChanges() {
        guard let rate = Double(hourlyRate) else { return }

        project.name = projectName
        project.hourlyRate = rate
        project.client = selectedClient

        try? modelContext.save()
        dismiss()
    }

    private func archiveProject() {
        project.isArchived = true
        try? modelContext.save()
        dismiss()
    }
}
