//
//  ExportManager.swift
//  Chirp
//
//  Export functionality for time entries (CSV, PDF, JSON backup)
//

import Foundation
import AppKit
import SwiftData

enum ExportManager {

    // MARK: - CSV Export

    /// Export time entries to CSV format with customization options
    static func exportToCSV(
        entries: [TimeEntry],
        fileName: String = "chirp_export",
        columns: [CSVColumn] = CSVColumn.allCases,
        dateFormat: CSVDateFormat = .short
    ) -> URL? {
        guard !entries.isEmpty, !columns.isEmpty else {
            LogManager.data.warning("Cannot export CSV: no entries or no columns selected")
            return nil
        }

        // Build header row
        var csvText = columns.map { $0.rawValue }.joined(separator: ",") + "\n"

        // Set up formatters
        let dateFormatter = dateFormat.formatter()
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let dayOfWeekFormatter = DateFormatter()
        dayOfWeekFormatter.dateFormat = "EEEE"

        // Process each entry
        for entry in entries.sorted(by: { $0.startTime > $1.startTime }) {
            var rowValues: [String] = []

            for column in columns {
                let value: String
                switch column {
                case .date:
                    value = dateFormatter.string(from: entry.startTime)
                case .dayOfWeek:
                    value = dayOfWeekFormatter.string(from: entry.startTime)
                case .project:
                    value = entry.project?.name ?? "Unknown"
                case .client:
                    value = entry.project?.client?.name ?? ""
                case .startTime:
                    value = timeFormatter.string(from: entry.startTime)
                case .endTime:
                    value = entry.endTime.map { timeFormatter.string(from: $0) } ?? "In Progress"
                case .duration:
                    value = String(format: "%.2f", entry.duration / 3600.0)
                case .hourlyRate:
                    value = String(format: "%.2f", entry.project?.hourlyRate ?? 0)
                case .earnings:
                    value = String(format: "%.2f", entry.earnings)
                case .notes:
                    value = entry.notes
                }

                rowValues.append(value.escapedForCSV)
            }

            csvText.append(rowValues.joined(separator: ",") + "\n")
        }

        LogManager.data.info("Exporting \(entries.count) entries to CSV with \(columns.count) columns")
        return saveToFile(content: csvText, fileName: "\(fileName).csv")
    }

    // MARK: - JSON Backup/Restore

    /// Create complete backup of all data
    static func createBackup(context: ModelContext) -> URL? {
        do {
            // Fetch all data
            let clients = try context.fetch(FetchDescriptor<Client>())
            let projects = try context.fetch(FetchDescriptor<Project>())
            let entries = try context.fetch(FetchDescriptor<TimeEntry>())
            let settings = try context.fetch(FetchDescriptor<UserSettings>())

            let backup = BackupData(
                version: "1.0",
                exportDate: Date(),
                clients: clients.map { BackupClient(from: $0) },
                projects: projects.map { BackupProject(from: $0) },
                entries: entries.map { BackupTimeEntry(from: $0) },
                settings: settings.first.map { BackupSettings(from: $0) }
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let jsonData = try encoder.encode(backup)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let fileName = "chirp_backup_\(dateFormatter.string(from: Date()))"

            return saveToFile(data: jsonData, fileName: "\(fileName).json")
        } catch {
            LogManager.data.error("Failed to create backup", error: error)
            return nil
        }
    }

    /// Restore data from backup file
    static func restoreBackup(from url: URL, context: ModelContext) throws {
        let jsonData = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(BackupData.self, from: jsonData)

        // Create client ID mapping
        var clientIDMap: [UUID: Client] = [:]

        // Restore clients
        for backupClient in backup.clients {
            let client = Client(
                name: backupClient.name,
                colorHex: backupClient.colorHex,
                defaultHourlyRate: backupClient.defaultHourlyRate
            )
            context.insert(client)
            clientIDMap[backupClient.id] = client
        }

        // Create project ID mapping
        var projectIDMap: [UUID: Project] = [:]

        // Restore projects
        for backupProject in backup.projects {
            let client = backupProject.clientID.flatMap { clientIDMap[$0] }
            let project = Project(
                name: backupProject.name,
                hourlyRate: backupProject.hourlyRate,
                client: client
            )
            project.isArchived = backupProject.isArchived
            project.lastUsedAt = backupProject.lastUsedAt
            context.insert(project)
            projectIDMap[backupProject.id] = project
        }

        // Restore time entries
        for backupEntry in backup.entries {
            if let project = projectIDMap[backupEntry.projectID] {
                let entry = TimeEntry(
                    project: project,
                    startTime: backupEntry.startTime,
                    notes: backupEntry.notes
                )
                entry.endTime = backupEntry.endTime
                context.insert(entry)
            }
        }

        // Restore settings
        if let backupSettings = backup.settings {
            let settings = UserSettings(
                userName: backupSettings.userName,
                currencyCode: backupSettings.currencyCode,
                defaultHourlyRate: backupSettings.defaultHourlyRate,
                showEarningsInMenuBar: backupSettings.showEarningsInMenuBar,
                roundTimeToNearestMinute: backupSettings.roundTimeToNearestMinute
            )
            context.insert(settings)
        }

        try context.save()
        LogManager.data.info("Successfully restored backup from \(url.lastPathComponent)")
    }

    // MARK: - File Helpers

    private static func saveToFile(content: String, fileName: String) -> URL? {
        guard let data = content.data(using: .utf8) else { return nil }
        return saveToFile(data: data, fileName: fileName)
    }

    private static func saveToFile(data: Data, fileName: String) -> URL? {
        // NSSavePanel MUST run on the main thread
        guard Thread.isMainThread else {
            var result: URL?
            DispatchQueue.main.sync {
                result = saveToFile(data: data, fileName: fileName)
            }
            return result
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fileName
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return nil
        }

        do {
            try data.write(to: url)
            LogManager.data.info("Successfully saved file: \(fileName)")
            return url
        } catch {
            LogManager.data.error("Failed to save file", error: error)
            return nil
        }
    }
}

// MARK: - Backup Data Structures

struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let clients: [BackupClient]
    let projects: [BackupProject]
    let entries: [BackupTimeEntry]
    let settings: BackupSettings?
}

struct BackupClient: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let defaultHourlyRate: Double

    init(from client: Client) {
        self.id = client.id
        self.name = client.name
        self.colorHex = client.colorHex
        self.defaultHourlyRate = client.defaultHourlyRate
    }
}

struct BackupProject: Codable {
    let id: UUID
    let name: String
    let hourlyRate: Double
    let isArchived: Bool
    let lastUsedAt: Date
    let clientID: UUID?

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.hourlyRate = project.hourlyRate
        self.isArchived = project.isArchived
        self.lastUsedAt = project.lastUsedAt
        self.clientID = project.client?.id
    }
}

struct BackupTimeEntry: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let notes: String
    let projectID: UUID

    init(from entry: TimeEntry) {
        self.id = entry.id
        self.startTime = entry.startTime
        self.endTime = entry.endTime
        self.notes = entry.notes
        self.projectID = entry.project?.id ?? UUID()
    }
}

struct BackupSettings: Codable {
    let userName: String
    let currencyCode: String
    let defaultHourlyRate: Double
    let showEarningsInMenuBar: Bool
    let roundTimeToNearestMinute: Int

    init(from settings: UserSettings) {
        self.userName = settings.userName
        self.currencyCode = settings.currencyCode
        self.defaultHourlyRate = settings.defaultHourlyRate
        self.showEarningsInMenuBar = settings.showEarningsInMenuBar
        self.roundTimeToNearestMinute = settings.roundTimeToNearestMinute
    }
}

// MARK: - String CSV Extension

extension String {
    var escapedForCSV: String {
        // Escape double quotes and wrap in quotes if contains comma, quote, or newline
        let escaped = self.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
