//
//  CSVExportSheet.swift
//  Chirp
//
//  CSV export options and customization sheet
//

import SwiftUI
import SwiftData

// MARK: - CSV Column Options

enum CSVColumn: String, CaseIterable, Identifiable {
    case date = "Date"
    case dayOfWeek = "Day of Week"
    case project = "Project"
    case client = "Client"
    case startTime = "Start Time"
    case endTime = "End Time"
    case duration = "Duration (Hours)"
    case hourlyRate = "Hourly Rate"
    case earnings = "Earnings"
    case notes = "Notes"

    var id: String { rawValue }
}

// MARK: - Date Format Options

enum CSVDateFormat: String, CaseIterable, Identifiable {
    case short = "Short (11/7/25)"
    case medium = "Medium (Nov 7, 2025)"
    case long = "Long (November 7, 2025)"
    case iso8601 = "ISO 8601 (2025-11-07)"

    var id: String { rawValue }

    func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        switch self {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .long:
            formatter.dateStyle = .long
        case .iso8601:
            formatter.dateFormat = "yyyy-MM-dd"
        }
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - Date Range Preset

enum DateRangePreset: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case allTime = "All Time"
    case custom = "Custom Range"

    func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
            return (interval.start, now)
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return (interval.start, now)
        case .last7Days:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
            return (start, now)
        case .last30Days:
            guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
            return (start, now)
        case .allTime:
            return nil // No filtering
        case .custom:
            return nil // Use custom dates
        }
    }
}

// MARK: - CSV Export Sheet

struct CSVExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var allProjects: [Project]

    let entries: [TimeEntry]

    // Column selection
    @State private var selectedColumns: Set<CSVColumn> = Set(CSVColumn.allCases)

    // Date format
    @State private var dateFormat: CSVDateFormat = .short

    // Date range
    @State private var dateRangePreset: DateRangePreset = .allTime
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()

    // Project filter
    @State private var selectedProjects: Set<UUID> = []
    @State private var showArchivedProjects = false

    private var availableProjects: [Project] {
        if showArchivedProjects {
            return allProjects
        } else {
            return allProjects.filter { !$0.isArchived }
        }
    }

    private var filteredEntries: [TimeEntry] {
        var result = entries

        // Filter by date range
        if dateRangePreset == .custom {
            result = result.filter { entry in
                entry.startTime >= customStartDate && entry.startTime <= customEndDate
            }
        } else if let range = dateRangePreset.dateRange() {
            result = result.filter { entry in
                entry.startTime >= range.start && entry.startTime <= range.end
            }
        }

        // Filter by projects
        if !selectedProjects.isEmpty {
            result = result.filter { entry in
                guard let projectID = entry.project?.id else { return false }
                return selectedProjects.contains(projectID)
            }
        }

        return result
    }

    private var estimatedFileSize: String {
        let avgBytesPerEntry = 150 // Rough estimate
        let totalBytes = filteredEntries.count * avgBytesPerEntry

        if totalBytes < 1024 {
            return "\(totalBytes) bytes"
        } else if totalBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024.0 * 1024.0))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Column Selection
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                        ForEach(CSVColumn.allCases) { column in
                            Toggle(column.rawValue, isOn: Binding(
                                get: { selectedColumns.contains(column) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedColumns.insert(column)
                                    } else {
                                        selectedColumns.remove(column)
                                    }
                                }
                            ))
                            .toggleStyle(.checkbox)
                        }
                    }

                    HStack {
                        Button("Select All") {
                            selectedColumns = Set(CSVColumn.allCases)
                        }
                        .buttonStyle(.link)

                        Button("Deselect All") {
                            selectedColumns.removeAll()
                        }
                        .buttonStyle(.link)
                    }
                } header: {
                    Text("Columns to Include")
                }

                // Date Format
                Section {
                    Picker("Date Format:", selection: $dateFormat) {
                        ForEach(CSVDateFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Date Format")
                }

                // Date Range
                Section {
                    Picker("Date Range:", selection: $dateRangePreset) {
                        ForEach(DateRangePreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)

                    if dateRangePreset == .custom {
                        DatePicker("From:", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("To:", selection: $customEndDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Date Range")
                }

                // Project Filter
                Section {
                    if availableProjects.isEmpty {
                        Text("No projects available")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                            ForEach(availableProjects) { project in
                                Toggle(isOn: Binding(
                                    get: { selectedProjects.contains(project.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedProjects.insert(project.id)
                                        } else {
                                            selectedProjects.remove(project.id)
                                        }
                                    }
                                )) {
                                    HStack {
                                        if let client = project.client {
                                            Circle()
                                                .fill(client.color)
                                                .frame(width: 8, height: 8)
                                        }
                                        Text(project.displayName)
                                    }
                                }
                                .toggleStyle(.checkbox)
                            }
                        }

                        HStack {
                            Button(selectedProjects.isEmpty ? "Select All" : "Deselect All") {
                                if selectedProjects.isEmpty {
                                    selectedProjects = Set(availableProjects.map { $0.id })
                                } else {
                                    selectedProjects.removeAll()
                                }
                            }
                            .buttonStyle(.link)

                            Spacer()

                            Toggle("Show Archived", isOn: $showArchivedProjects)
                                .toggleStyle(.checkbox)
                        }
                    }
                } header: {
                    Text("Filter by Projects")
                } footer: {
                    Text("Leave all projects unchecked to export all entries")
                        .font(DesignSystem.Typography.caption)
                }

                // Preview
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Entries to Export")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text("\(filteredEntries.count)")
                                .font(DesignSystem.Typography.title3.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Est. File Size")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text(estimatedFileSize)
                                .font(DesignSystem.Typography.title3.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Export Preview")
                }
            }
            .formStyle(.grouped)
            .frame(width: 600, height: 700)
            .navigationTitle("CSV Export Options")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        performExport()
                    }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    private var isValid: Bool {
        !selectedColumns.isEmpty && !filteredEntries.isEmpty
    }

    private func performExport() {
        // Generate filename based on date range
        let fileName: String
        if dateRangePreset == .custom {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            fileName = "chirp_export_\(df.string(from: customStartDate))_to_\(df.string(from: customEndDate))"
        } else {
            fileName = "chirp_export_\(dateRangePreset.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }

        if let url = ExportManager.exportToCSV(
            entries: filteredEntries,
            fileName: fileName,
            columns: Array(selectedColumns).sorted(by: { CSVColumn.allCases.firstIndex(of: $0)! < CSVColumn.allCases.firstIndex(of: $1)! }),
            dateFormat: dateFormat
        ) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
            dismiss()
        }
    }
}
