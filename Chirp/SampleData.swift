//
//  SampleData.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import Foundation
import SwiftData

@MainActor
class SampleDataManager {
    static func createSampleData(context: ModelContext) {
        // Check if we already have data
        let descriptor = FetchDescriptor<Client>()
        do {
            let count = try context.fetchCount(descriptor)
            if count > 0 {
                return // Already have data
            }
        } catch {
            print("❌ SampleDataManager: Failed to fetch client count: \(error)")
            return
        }

        // Create sample clients
        let acmeCorp = Client(name: "Acme Corp", colorHex: "007AFF", defaultHourlyRate: 150)
        let techStartup = Client(name: "Tech Startup", colorHex: "34C759", defaultHourlyRate: 120)
        let designStudio = Client(name: "Design Studio", colorHex: "FF2D55", defaultHourlyRate: 100)

        context.insert(acmeCorp)
        context.insert(techStartup)
        context.insert(designStudio)

        // Create sample projects
        let website = Project(name: "Website Redesign", hourlyRate: 150, client: acmeCorp)
        let mobileApp = Project(name: "Mobile App", hourlyRate: 120, client: techStartup)
        let branding = Project(name: "Brand Identity", hourlyRate: 100, client: designStudio)
        let personalProject = Project(name: "Personal Research", hourlyRate: 0, client: nil)

        context.insert(website)
        context.insert(mobileApp)
        context.insert(branding)
        context.insert(personalProject)

        // Create some sample time entries from the past few days
        let calendar = Calendar.current
        let now = Date()

        // Today's entries
        if let today9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now),
           let today10am = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now) {
            let entry1 = TimeEntry(project: website, startTime: today9am, notes: "Morning planning session")
            entry1.endTime = today10am
            context.insert(entry1)
        }

        if let today11am = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now),
           let today1pm = calendar.date(bySettingHour: 13, minute: 15, second: 0, of: now) {
            let entry2 = TimeEntry(project: mobileApp, startTime: today11am, notes: "Implementing authentication flow")
            entry2.endTime = today1pm
            context.insert(entry2)
        }

        // Yesterday's entries
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           let yesterday9am = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: yesterday),
           let yesterday11am = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: yesterday),
           let yesterday2pm = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: yesterday),
           let yesterday5pm = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: yesterday) {

            let entry3 = TimeEntry(project: website, startTime: yesterday9am, notes: "Homepage mockups")
            entry3.endTime = yesterday11am
            context.insert(entry3)

            let entry4 = TimeEntry(project: branding, startTime: yesterday2pm, notes: "Logo concepts")
            entry4.endTime = yesterday5pm
            context.insert(entry4)
        }

        // Day before yesterday
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now),
           let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: twoDaysAgo),
           let end = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: twoDaysAgo) {

            let entry5 = TimeEntry(project: mobileApp, startTime: start, notes: "Code review and bug fixes")
            entry5.endTime = end
            context.insert(entry5)
        }

        do {
            try context.save()
        } catch {
            print("❌ SampleDataManager: Failed to save sample data: \(error)")
        }
    }
}
