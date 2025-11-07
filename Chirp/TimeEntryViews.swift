//
//  TimeEntryViews.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData

// MARK: - Edit Time Entry Sheet
struct EditTimeEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]

    let entry: TimeEntry

    @State private var selectedProject: Project?
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var showDeleteConfirmation = false

    init(entry: TimeEntry) {
        self.entry = entry
        _selectedProject = State(initialValue: entry.project)
        _startTime = State(initialValue: entry.startTime)
        _endTime = State(initialValue: entry.endTime ?? Date())
        _notes = State(initialValue: entry.notes)
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var earnings: Double {
        guard let project = selectedProject else { return 0 }
        let hours = duration / 3600.0
        return hours * project.hourlyRate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    Picker("Project:", selection: $selectedProject) {
                        Text("No project").tag(nil as Project?)
                        ForEach(projects.filter { !$0.isArchived }) { project in
                            HStack {
                                if let client = project.client {
                                    Circle()
                                        .fill(client.color)
                                        .frame(width: 12, height: 12)
                                }
                                Text(project.displayName)
                            }
                            .tag(project as Project?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Time") {
                    DatePicker("Start:", selection: $startTime)
                    DatePicker("End:", selection: $endTime)

                    // Summary card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text(duration.formattedShort)
                                .font(DesignSystem.Typography.callout.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        Spacer()
                        if selectedProject != nil {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Earnings")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text(earnings.formattedCurrency)
                                    .font(DesignSystem.Typography.callout.weight(.semibold))
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Notes") {
                    TextField("Description of work", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Entry", systemImage: "trash")
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 550)
            .controlSize(.regular)
            .navigationTitle("Edit Time Entry")
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
            .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("Are you sure you want to delete this time entry? This action cannot be undone.")
            }
        }
    }

    private var isValid: Bool {
        endTime > startTime
    }

    private func saveChanges() {
        entry.project = selectedProject
        entry.startTime = startTime
        entry.endTime = endTime
        entry.notes = notes

        try? modelContext.save()
        dismiss()
    }

    private func deleteEntry() {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Manual Time Entry Sheet
struct ManualTimeEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.lastUsedAt, order: .reverse) private var projects: [Project]

    @State private var selectedProject: Project?
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var useDuration = false
    @State private var durationHours = 0
    @State private var durationMinutes = 0

    var calculatedEndTime: Date {
        if useDuration {
            let totalSeconds = TimeInterval(durationHours * 3600 + durationMinutes * 60)
            return startTime.addingTimeInterval(totalSeconds)
        }
        return endTime
    }

    var duration: TimeInterval {
        calculatedEndTime.timeIntervalSince(startTime)
    }

    var earnings: Double {
        guard let project = selectedProject else { return 0 }
        let hours = duration / 3600.0
        return hours * project.hourlyRate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    Picker("Project:", selection: $selectedProject) {
                        Text("Choose a project").tag(nil as Project?)
                        ForEach(projects.filter { !$0.isArchived }) { project in
                            HStack {
                                if let client = project.client {
                                    Circle()
                                        .fill(client.color)
                                        .frame(width: 12, height: 12)
                                }
                                Text(project.displayName)
                            }
                            .tag(project as Project?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Time") {
                    DatePicker("Start:", selection: $startTime)

                    Toggle("Enter Duration", isOn: $useDuration)

                    if useDuration {
                        HStack {
                            Picker("Hours:", selection: $durationHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour) hours").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)

                            Picker("Minutes:", selection: $durationMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                        }

                        HStack {
                            Text("End Time:")
                            Spacer()
                            Text(calculatedEndTime, style: .time)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    } else {
                        DatePicker("End:", selection: $endTime)
                    }

                    // Summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text(duration.formattedShort)
                                .font(DesignSystem.Typography.callout.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        Spacer()
                        if selectedProject != nil {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Earnings")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text(earnings.formattedCurrency)
                                    .font(DesignSystem.Typography.callout.weight(.semibold))
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Notes") {
                    TextField("What did you work on?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .frame(width: 520, height: 600)
            .controlSize(.regular)
            .navigationTitle("Add Time Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    private var isValid: Bool {
        guard selectedProject != nil else { return false }

        if useDuration {
            return durationHours > 0 || durationMinutes > 0
        } else {
            return endTime > startTime
        }
    }

    private func addEntry() {
        guard let project = selectedProject else { return }

        let entry = TimeEntry(project: project, startTime: startTime, notes: notes)
        entry.endTime = calculatedEndTime

        project.lastUsedAt = Date()

        modelContext.insert(entry)
        try? modelContext.save()

        dismiss()
    }
}

