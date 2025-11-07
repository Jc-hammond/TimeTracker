//
//  MenuBarPopoverView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]

    let manager: MenuBarManager

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var activeSession: FocusSession? {
        sessions.first(where: { $0.isActive })
    }

    var todayTasks: [TaskItem] {
        tasks.filter { $0.isDailyIntention && !$0.isCompleted }
            .prefix(3)
            .map { $0 }
    }

    var todayStats: (hours: Double, completed: Int, sessions: Int) {
        let todaySessions = sessions.filter { Calendar.current.isDateInToday($0.startTime) && $0.endTime != nil }
        let hours = todaySessions.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let completed = tasks.filter {
            if let completedAt = $0.completedAt {
                return Calendar.current.isDateInToday(completedAt)
            }
            return false
        }.count
        return (hours, completed, todaySessions.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.orange)
                Text("Chirp")
                    .font(.headline)
                Spacer()
                Button {
                    manager.showMainWindow()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))

            ScrollView {
                VStack(spacing: 16) {
                    // Active Session
                    if let session = activeSession {
                        activeSessionCard(session)
                    } else {
                        quickStartButtons
                    }

                    // Today's Stats
                    todayStatsCard

                    // Quick Tasks
                    if !todayTasks.isEmpty {
                        quickTasksCard
                    }
                }
                .padding()
            }
        }
        .frame(width: 360, height: 400)
        .onAppear {
            if activeSession != nil {
                startTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Active Session Card
    @ViewBuilder
    func activeSessionCard(_ session: FocusSession) -> some View {
        VStack(spacing: 12) {
            // Category and Type
            HStack {
                Label(session.category.rawValue, systemImage: session.category.icon)
                    .font(.subheadline)
                    .foregroundStyle(session.category.color)

                Spacer()

                Text(session.sessionType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Timer
            Text(timeString(for: session))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            // Progress
            ProgressView(value: progressValue(for: session))
                .tint(session.category.color)

            // Task (if any)
            if let taskTitle = session.taskTitle {
                Text(taskTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Controls
            HStack(spacing: 12) {
                Button {
                    if session.isPaused {
                        session.resume()
                    } else {
                        session.pause()
                    }
                } label: {
                    Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    session.complete()
                    manager.currentSession = nil
                } label: {
                    Image(systemName: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // Add Interruption
            Button {
                session.addInterruption()
            } label: {
                Label("Interruption (\(session.interruptionCount))", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(session.category.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Start Buttons
    var quickStartButtons: some View {
        VStack(spacing: 12) {
            Text("Start Focus Session")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach([SessionType.sprint, .deepWork, .flowState], id: \.self) { type in
                    Button {
                        manager.startQuickSession(type: type)
                        startTimer()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.headline)
                                Text("\(Int(type.defaultDuration / 60)) minutes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Today's Stats
    var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            HStack(spacing: 16) {
                StatBadge(
                    icon: "clock.fill",
                    value: String(format: "%.1fh", todayStats.hours),
                    color: .blue
                )

                StatBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(todayStats.completed)",
                    color: .green
                )

                StatBadge(
                    icon: "flame.fill",
                    value: "\(todayStats.sessions)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Tasks
    var quickTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Must-Do", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                ForEach(todayTasks) { task in
                    Button {
                        task.toggleComplete()
                    } label: {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? .green : .secondary)

                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Views
    struct StatBadge: View {
        let icon: String
        let value: String
        let color: Color

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helper Methods
    func progressValue(for session: FocusSession) -> Double {
        // Use elapsedTime to force update
        _ = elapsedTime
        return session.progress
    }

    func timeString(for session: FocusSession) -> String {
        // Use elapsedTime to force SwiftUI to recalculate every second
        _ = elapsedTime

        let remaining = session.plannedDuration - session.actualDuration
        let duration = max(remaining, 0)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
}

#Preview {
    MenuBarPopoverView(manager: MenuBarManager.shared)
        .modelContainer(for: [FocusSession.self, TaskItem.self, DailyLog.self], inMemory: true)
}
