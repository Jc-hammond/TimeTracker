//
//  TimerManager.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

class TimerManager: ObservableObject {
    @Published var activeEntry: TimeEntry?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentNotes: String = ""
    @Published var isPaused: Bool = false

    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    private var totalPausedDuration: TimeInterval = 0

    private let defaults = UserDefaults.standard
    private let timerStateKey = "activeTimerState"

    var isTracking: Bool {
        activeEntry != nil
    }

    init() {
        // Timer state is restored via restoreTimerState() called from app
    }

    // MARK: - Persistence
    func saveTimerState() {
        guard let entry = activeEntry, let start = startTime else {
            defaults.removeObject(forKey: timerStateKey)
            return
        }

        let state: [String: Any] = [
            "startTime": start,
            "notes": currentNotes,
            "isPaused": isPaused,
            "pausedTime": pausedTime as Any,
            "totalPausedDuration": totalPausedDuration,
            "projectName": entry.project?.name ?? "",
            "clientName": entry.project?.client?.name ?? ""
        ]

        defaults.set(state, forKey: timerStateKey)
    }

    func restoreTimerState(modelContext: ModelContext) {
        guard let state = defaults.dictionary(forKey: timerStateKey),
              let savedStartTime = state["startTime"] as? Date,
              let projectName = state["projectName"] as? String else {
            return
        }

        // Find the project
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { project in
                project.name == projectName
            }
        )

        guard let projects = try? modelContext.fetch(descriptor),
              let project = projects.first else {
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

        updateElapsedTime()
    }

    func clearTimerState() {
        defaults.removeObject(forKey: timerStateKey)
    }

    // MARK: - Timer Control
    func startTimer(for project: Project, notes: String = "") {
        // Stop any existing timer
        stopTimer()

        // Create new time entry
        let entry = TimeEntry(project: project, startTime: Date(), notes: notes)
        activeEntry = entry
        startTime = Date()
        currentNotes = notes
        elapsedTime = 0
        isPaused = false
        pausedTime = nil
        totalPausedDuration = 0

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

        entry.endTime = Date()
        entry.notes = currentNotes

        let stoppedEntry = entry
        activeEntry = nil
        elapsedTime = 0
        currentNotes = ""
        startTime = nil
        isPaused = false
        pausedTime = nil
        totalPausedDuration = 0

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
}
