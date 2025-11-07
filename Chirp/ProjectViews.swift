//
//  ProjectViews.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData

// MARK: - Project Picker Sheet
struct ProjectPickerSheet: View {
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
    @FocusState private var focusedField: Field?

    enum Field {
        case projectName, hourlyRate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Name:", text: $projectName)
                        .focused($focusedField, equals: .projectName)
                        .help("Enter the project name")

                    TextField("Hourly rate:", text: $hourlyRate)
                        .focused($focusedField, equals: .hourlyRate)
                        .help("Enter the hourly rate in USD")
                }

                Section("Client") {
                    Picker("Client:", selection: $selectedClient) {
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
                    .pickerStyle(.menu)

                    Button("Create New Client...") {
                        showingNewClient = true
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 480, height: 400)
            .controlSize(.regular)
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(projectName.isEmpty || hourlyRate.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear {
                focusedField = .projectName
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
    @FocusState private var isNameFieldFocused: Bool

    let onClientCreated: (Client) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Name:", text: $clientName)
                        .focused($isNameFieldFocused)
                        .help("Enter the client name")

                    TextField("Default rate:", text: $defaultRate)
                        .help("Optional default hourly rate for new projects")
                }

                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                        Text("Choose a color to identify this client")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: DesignSystem.Spacing.comfortable) {
                            ForEach(DesignSystem.Colors.clientColors, id: \.self) { colorHex in
                                Button(action: { selectedColorHex = colorHex }) {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(DesignSystem.Colors.accent, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                        )
                                        .shadow(color: Color(hex: colorHex).opacity(0.3), radius: selectedColorHex == colorHex ? 4 : 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.close)
                    }
                } header: {
                    Text("Color")
                }
            }
            .formStyle(.grouped)
            .frame(width: 480, height: 450)
            .controlSize(.regular)
            .navigationTitle("New Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createClient()
                    }
                    .disabled(clientName.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear {
                isNameFieldFocused = true
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
    @State private var projectToEdit: Project?
    @State private var projectToArchive: Project?

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
                    ProjectListRow(project: project) {
                        projectToEdit = project
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            projectToArchive = project
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }

                        Button {
                            projectToEdit = project
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
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
        .sheet(item: $projectToEdit) { project in
            EditProjectSheet(project: project)
        }
        .alert("Archive Project", isPresented: .init(
            get: { projectToArchive != nil },
            set: { if !$0 { projectToArchive = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                projectToArchive = nil
            }
            Button("Archive", role: .destructive) {
                if let project = projectToArchive {
                    archiveProject(project)
                }
            }
        } message: {
            if let project = projectToArchive {
                Text("Are you sure you want to archive '\(project.name)'? You can still see archived projects and their time entries, but they won't appear in active lists.")
            }
        }
    }

    private func archiveProject(_ project: Project) {
        project.isArchived = true
        try? modelContext.save()
        projectToArchive = nil
    }

    private func deleteProjects(at offsets: IndexSet) {
        let currentFiltered = filteredProjects
        let targets = offsets.compactMap { index -> Project? in
            guard currentFiltered.indices.contains(index) else { return nil }
            return currentFiltered[index]
        }
        for project in targets {
            project.isArchived = true
        }
        try? modelContext.save()
    }
}

struct ProjectListRow: View {
    let project: Project
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
            }
        }
        .buttonStyle(.plain)
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
    @State private var showPermanentDeleteConfirmation = false
    @FocusState private var focusedField: Field?

    enum Field {
        case projectName, hourlyRate
    }

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
                    TextField("Name:", text: $projectName)
                        .focused($focusedField, equals: .projectName)
                        .help("Enter the project name")

                    TextField("Hourly rate:", text: $hourlyRate)
                        .focused($focusedField, equals: .hourlyRate)
                        .help("Enter the hourly rate in USD")
                }

                Section("Client") {
                    Picker("Client:", selection: $selectedClient) {
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
                    .pickerStyle(.menu)

                    Button("Create New Client...") {
                        showingNewClient = true
                    }
                }

                Section {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Archive Project", systemImage: "archivebox")
                    }
                }

                Section {
                    Button(role: .destructive, action: { showPermanentDeleteConfirmation = true }) {
                        Label("Delete Project Permanently", systemImage: "trash")
                    }
                } footer: {
                    Text("Permanently deletes this project and all associated time entries. This cannot be undone.")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .formStyle(.grouped)
            .frame(width: 480, height: 450)
            .controlSize(.regular)
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear {
                focusedField = .projectName
            }
            .alert("Archive Project", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    archiveProject()
                }
            } message: {
                Text("Are you sure you want to archive '\(project.name)'? You can still see archived projects and their time entries, but they won't appear in active lists.")
            }
            .alert("Delete Project Permanently", isPresented: $showPermanentDeleteConfirmation) {
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

    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
        dismiss()
    }
}
