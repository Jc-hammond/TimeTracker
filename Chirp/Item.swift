//
//  Models.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Client {
    var id: UUID
    var name: String
    var colorHex: String
    var defaultHourlyRate: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Project.client)
    var projects: [Project]?

    init(name: String, colorHex: String = "FF6B35", defaultHourlyRate: Double = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.defaultHourlyRate = defaultHourlyRate
        self.createdAt = Date()
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

@Model
final class Project {
    var id: UUID
    var name: String
    var hourlyRate: Double
    var isArchived: Bool
    var createdAt: Date
    var lastUsedAt: Date

    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.project)
    var timeEntries: [TimeEntry]?

    init(name: String, hourlyRate: Double, client: Client? = nil) {
        self.id = UUID()
        self.name = name
        self.hourlyRate = hourlyRate
        self.client = client
        self.isArchived = false
        self.createdAt = Date()
        self.lastUsedAt = Date()
    }

    var displayName: String {
        if let client = client {
            return "\(client.name) - \(name)"
        }
        return name
    }
}

@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var notes: String
    var manualDuration: TimeInterval?

    var project: Project?

    init(project: Project?, startTime: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.project = project
        self.startTime = startTime
        self.notes = notes
    }

    var duration: TimeInterval {
        if let manualDuration = manualDuration {
            return manualDuration
        }
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var earnings: Double {
        guard let project = project else { return 0 }
        let hours = duration / 3600.0
        return hours * project.hourlyRate
    }

    var isRunning: Bool {
        endTime == nil
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "000000"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
