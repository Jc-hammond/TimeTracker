//
//  DailyLog.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date

    // Energy and mood tracking (1-5 scale)
    var morningEnergy: Int?
    var afternoonEnergy: Int?
    var eveningEnergy: Int?
    var overallMood: Int?

    // Reflection
    var wins: [String]
    var challenges: [String]
    var learnings: [String]

    // Momentum tracking
    var momentumScore: Double? // Calculated based on various factors

    // Quick notes
    var dailyNotes: String?

    init(date: Date = Date()) {
        self.id = UUID()
        // Normalize to start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.wins = []
        self.challenges = []
        self.learnings = []
    }

    // Computed properties
    var averageEnergy: Double? {
        let energies = [morningEnergy, afternoonEnergy, eveningEnergy].compactMap { $0 }
        guard !energies.isEmpty else { return nil }
        return Double(energies.reduce(0, +)) / Double(energies.count)
    }

    var hasAnyEntry: Bool {
        morningEnergy != nil ||
        afternoonEnergy != nil ||
        eveningEnergy != nil ||
        overallMood != nil ||
        !wins.isEmpty ||
        !challenges.isEmpty ||
        !learnings.isEmpty ||
        dailyNotes != nil
    }

    // Methods
    func addWin(_ win: String) {
        wins.append(win)
    }

    func addChallenge(_ challenge: String) {
        challenges.append(challenge)
    }

    func addLearning(_ learning: String) {
        learnings.append(learning)
    }

    func removeWin(at index: Int) {
        guard wins.indices.contains(index) else { return }
        wins.remove(at: index)
    }

    func removeChallenge(at index: Int) {
        guard challenges.indices.contains(index) else { return }
        challenges.remove(at: index)
    }

    func removeLearning(at index: Int) {
        guard learnings.indices.contains(index) else { return }
        learnings.remove(at: index)
    }
}
