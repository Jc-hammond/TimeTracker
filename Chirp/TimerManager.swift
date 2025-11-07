//
//  TimerManager.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import Foundation
import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var activeEntry: TimeEntry?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentNotes: String = ""

    private var timer: Timer?
    private var startTime: Date?

    var isTracking: Bool {
        activeEntry != nil
    }

    func startTimer(for project: Project, notes: String = "") {
        // Stop any existing timer
        stopTimer()

        // Create new time entry
        let entry = TimeEntry(project: project, startTime: Date(), notes: notes)
        activeEntry = entry
        startTime = Date()
        currentNotes = notes
        elapsedTime = 0

        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
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

        return stoppedEntry
    }

    func updateNotes(_ notes: String) {
        currentNotes = notes
        activeEntry?.notes = notes
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
