//
//  TaskItem.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case mustDo = "Must Do"      // Critical daily intentions
    case shouldDo = "Should Do"  // Important but flexible
    case couldDo = "Could Do"    // Nice to have

    var id: String { rawValue }
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var category: TaskCategory
    var priority: TaskPriority
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    // Time tracking
    var estimatedMinutes: Int?
    var actualMinutes: Int?

    // Optional details
    var notes: String?

    // Daily intention flag
    var isDailyIntention: Bool

    init(
        title: String,
        category: TaskCategory,
        priority: TaskPriority = .shouldDo,
        estimatedMinutes: Int? = nil,
        isDailyIntention: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
        self.estimatedMinutes = estimatedMinutes
        self.isDailyIntention = isDailyIntention
    }

    // Computed properties
    var isOverdue: Bool {
        !isCompleted && isDailyIntention && !Calendar.current.isDateInToday(createdAt)
    }

    var timeVariance: Int? {
        guard let estimated = estimatedMinutes,
              let actual = actualMinutes else { return nil }
        return actual - estimated
    }

    // Methods
    func complete(actualMinutes: Int? = nil) {
        isCompleted = true
        completedAt = Date()
        if let minutes = actualMinutes {
            self.actualMinutes = minutes
        }
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }

    func toggleComplete() {
        if isCompleted {
            uncomplete()
        } else {
            complete()
        }
    }
}
