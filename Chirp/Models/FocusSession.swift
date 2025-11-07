//
//  FocusSession.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case sprint = "Sprint"          // 25 minutes - Pomodoro-style for quick tasks
    case deepWork = "Deep Work"     // 90-120 minutes - Standard deep work
    case flowState = "Flow State"   // 180-240 minutes - Maximum focus

    var id: String { rawValue }

    var defaultDuration: TimeInterval {
        switch self {
        case .sprint: return 25 * 60        // 25 minutes
        case .deepWork: return 90 * 60      // 90 minutes
        case .flowState: return 180 * 60    // 180 minutes
        }
    }

    var description: String {
        switch self {
        case .sprint: return "Quick focused burst for smaller tasks"
        case .deepWork: return "Extended focus for complex development"
        case .flowState: return "Maximum uninterrupted deep work"
        }
    }
}

@Model
final class FocusSession {
    var id: UUID
    var sessionType: SessionType
    var category: TaskCategory
    var startTime: Date
    var endTime: Date?
    var plannedDuration: TimeInterval
    var isPaused: Bool
    var pausedAt: Date?
    var totalPausedTime: TimeInterval

    // Quality metrics
    var interruptionCount: Int
    var focusQuality: Int? // 1-5 scale, set at end
    var energyLevel: Int? // 1-5 scale, set at end

    // Optional associations
    var taskTitle: String?
    var notes: String?

    init(
        sessionType: SessionType,
        category: TaskCategory,
        startTime: Date = Date(),
        plannedDuration: TimeInterval? = nil,
        taskTitle: String? = nil
    ) {
        self.id = UUID()
        self.sessionType = sessionType
        self.category = category
        self.startTime = startTime
        self.plannedDuration = plannedDuration ?? sessionType.defaultDuration
        self.isPaused = false
        self.totalPausedTime = 0
        self.interruptionCount = 0
        self.taskTitle = taskTitle
    }

    // Computed properties
    var isActive: Bool {
        endTime == nil
    }

    var actualDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) - totalPausedTime
    }

    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(actualDuration / plannedDuration, 1.0)
    }

    // Methods
    func pause() {
        guard !isPaused, endTime == nil else { return }
        isPaused = true
        pausedAt = Date()
    }

    func resume() {
        guard isPaused, let pausedAt = pausedAt else { return }
        totalPausedTime += Date().timeIntervalSince(pausedAt)
        isPaused = false
        self.pausedAt = nil
    }

    func addInterruption() {
        interruptionCount += 1
    }

    func complete(focusQuality: Int? = nil, energyLevel: Int? = nil, notes: String? = nil) {
        endTime = Date()
        self.focusQuality = focusQuality
        self.energyLevel = energyLevel
        if let notes = notes {
            self.notes = notes
        }
    }
}
