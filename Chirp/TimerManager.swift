//
//  TimerManager.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
final class TimerManager: ObservableObject {
    @Published var activeEntry: TimeEntry?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentNotes: String = ""
    @Published var isPaused: Bool = false

    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var modelContext: ModelContext?

    private let defaults = UserDefaults.standard
    private let timerStateKey = "activeTimerState"

    var isTracking: Bool {
        activeEntry != nil
    }

    init() {
        // Timer state is restored via restoreTimerState() called from app
    }

    deinit {
        timer?.invalidate()
    }

    func configure(with context: ModelContext) {
        modelContext = context
    }

    // MARK: - Persistence
    func saveTimerState() {
        guard let entry = activeEntry, let start = startTime else {
            defaults.removeObject(forKey: timerStateKey)
            return
        }

        var state: [String: Any] = [
            "startTime": start,
            "notes": currentNotes,
            "isPaused": isPaused,
            "totalPausedDuration": totalPausedDuration,
            "projectID": entry.project?.id.uuidString ?? ""
        ]

        // Only include pausedTime if it exists (avoid NSNull in UserDefaults)
        if let pausedTime = pausedTime {
            state["pausedTime"] = pausedTime
        }

        defaults.set(state, forKey: timerStateKey)
    }

    func restoreTimerState() {
        guard let context = modelContext,
              let state = defaults.dictionary(forKey: timerStateKey),
              let savedStartTime = state["startTime"] as? Date else {
            return
        }

        guard let projectIDString = state["projectID"] as? String,
              let projectID = UUID(uuidString: projectIDString),
              !projectIDString.isEmpty else {
            clearTimerState()
            return
        }

        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { project in
                project.id == projectID
            }
        )

        let project: Project
        do {
            guard let fetchedProject = try context.fetch(descriptor).first else {
                clearTimerState()
                return
            }
            project = fetchedProject
        } catch {
            LogManager.timer.error("Failed to fetch project while restoring timer", error: error)
            clearTimerState()
            return
        }

        // Restore state
        let notes = state["notes"] as? String ?? ""
        let wasPaused = state["isPaused"] as? Bool ?? false
        let savedPausedTime = state["pausedTime"] as? Date
        let savedPausedDuration = state["totalPausedDuration"] as? TimeInterval ?? 0

        // Create entry
        let entry = TimeEntry(project: project, startTime: savedStartTime, notes: notes)
        activeEntry = entry
        startTime = savedStartTime
        currentNotes = notes
        isPaused = wasPaused
        pausedTime = savedPausedTime
        totalPausedDuration = savedPausedDuration

        if !isPaused {
            startTimer()
        }

        let referenceDate = isPaused ? (savedPausedTime ?? Date()) : Date()
        let computedElapsed = max(0, referenceDate.timeIntervalSince(savedStartTime) - savedPausedDuration)
        elapsedTime = computedElapsed
    }

    func clearTimerState() {
        defaults.removeObject(forKey: timerStateKey)
    }

    // MARK: - Timer Control
    func startTimer(for project: Project, notes: String = "") {
        // Persist any existing entry before starting a new one
        _ = stopTimer()

        // Create new time entry
        let now = Date()
        let entry = TimeEntry(project: project, startTime: now, notes: notes)
        activeEntry = entry
        startTime = now
        currentNotes = notes
        elapsedTime = 0
        isPaused = false
        pausedTime = nil
        totalPausedDuration = 0

        project.lastUsedAt = Date()
        if let context = modelContext {
            do {
                try context.save()
            } catch {
                LogManager.timer.error("Failed to save context when starting timer", error: error)
            }
        }

        startTimer()
        saveTimerState()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func updateElapsedTime() {
        guard let start = startTime else { return }

        if isPaused {
            // When paused, elapsed time doesn't change
            return
        }

        let totalElapsed = Date().timeIntervalSince(start)
        elapsedTime = totalElapsed - totalPausedDuration
    }

    func pauseTimer() {
        guard isTracking, !isPaused else { return }

        if let start = startTime {
            elapsedTime = Date().timeIntervalSince(start) - totalPausedDuration
        }

        isPaused = true
        pausedTime = Date()
        timer?.invalidate()
        timer = nil
        saveTimerState()
    }

    func resumeTimer() {
        guard isTracking, isPaused, let paused = pausedTime else { return }

        let pauseDuration = Date().timeIntervalSince(paused)
        totalPausedDuration += pauseDuration

        isPaused = false
        pausedTime = nil

        startTimer()
        saveTimerState()
    }

    func stopTimer() -> TimeEntry? {
        timer?.invalidate()
        timer = nil

        guard let entry = activeEntry else { return nil }

        // Check if project still exists (could have been deleted)
        if entry.project == nil {
            LogManager.timer.warning("Timer stopped but project was deleted. Entry discarded.")
            resetState()
            clearTimerState()
            return nil
        }

        entry.endTime = Date()
        entry.notes = currentNotes

        persist(entry)

        let stoppedEntry = entry
        resetState()
        clearTimerState()

        return stoppedEntry
    }

    func updateNotes(_ notes: String) {
        currentNotes = notes
        activeEntry?.notes = notes
        saveTimerState()
    }

    var formattedTime: String {
        elapsedTime.formattedDuration
    }

    var currentEarnings: Double {
        guard let project = activeEntry?.project else { return 0 }
        let hours = elapsedTime / 3600.0
        return hours * project.hourlyRate
    }

    // MARK: - Persistence Helpers
    private func persist(_ entry: TimeEntry) {
        guard let context = modelContext else { return }

        context.insert(entry)
        do {
            try context.save()
        } catch {
            LogManager.data.error("Failed to save time entry", error: error)
        }
    }

    private func resetState() {
        activeEntry = nil
        elapsedTime = 0
        currentNotes = ""
        startTime = nil
        isPaused = false
        pausedTime = nil
        totalPausedDuration = 0
    }
}
