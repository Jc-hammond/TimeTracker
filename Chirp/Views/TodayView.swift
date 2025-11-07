//
//  TodayView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]
    @Query private var logs: [DailyLog]

    var todaySessions: [FocusSession] {
        sessions.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    var activeSession: FocusSession? {
        sessions.first(where: { $0.isActive })
    }

    var todayTasks: [TaskItem] {
        tasks.filter { Calendar.current.isDateInToday($0.createdAt) || $0.isDailyIntention }
    }

    var completedToday: [TaskItem] {
        tasks.filter {
            if let completedAt = $0.completedAt {
                return Calendar.current.isDateInToday(completedAt)
            }
            return false
        }
    }

    var totalDeepWorkToday: TimeInterval {
        todaySessions
            .filter { $0.endTime != nil }
            .reduce(0) { $0 + $1.actualDuration }
    }

    var todayLog: DailyLog {
        if let log = logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
            return log
        } else {
            let log = DailyLog(date: Date())
            modelContext.insert(log)
            return log
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Date
                VStack(spacing: 8) {
                    Text(Date(), style: .date)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Today's Focus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Current Session (if active)
                if let session = activeSession {
                    CurrentSessionCard(session: session)
                }

                // Today's Stats
                HStack(spacing: 16) {
                    StatCard(
                        icon: "clock.fill",
                        title: "Deep Work",
                        value: formatHours(totalDeepWorkToday),
                        color: .blue
                    )

                    StatCard(
                        icon: "checkmark.circle.fill",
                        title: "Completed",
                        value: "\(completedToday.count)",
                        color: .green
                    )

                    StatCard(
                        icon: "flame.fill",
                        title: "Sessions",
                        value: "\(todaySessions.filter { $0.endTime != nil }.count)",
                        color: .orange
                    )
                }

                // Daily Intentions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Today's Must-Do Items", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        Spacer()

                        let dailyIntentions = todayTasks.filter { $0.isDailyIntention }
                        let completed = dailyIntentions.filter { $0.isCompleted }.count

                        Text("\(completed)/\(dailyIntentions.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    let intentions = todayTasks.filter { $0.isDailyIntention }

                    if intentions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)

                            Text("No daily intentions yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Set 1-3 must-do items for today in the Tasks view")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(intentions) { task in
                                QuickTaskRow(task: task)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Energy Check-in
                EnergyCheckIn(log: todayLog)

                // Recent Activity
                if !completedToday.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Completed Today", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        VStack(spacing: 8) {
                            ForEach(completedToday.prefix(5)) { task in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.body)

                                        HStack {
                                            Label(task.category.rawValue, systemImage: task.category.icon)
                                                .font(.caption)
                                                .foregroundStyle(task.category.color)

                                            if let completedAt = task.completedAt {
                                                Text(completedAt, style: .time)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    func formatHours(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

struct CurrentSessionCard: View {
    let session: FocusSession

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Focus Session in Progress", systemImage: "timer")
                    .font(.headline)

                Spacer()

                if session.isPaused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.category.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(session.category.color)

                    if let taskTitle = session.taskTitle {
                        Text(taskTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Started \(session.startTime, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack {
                    Text(timeString)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    ProgressView(value: session.progress)
                        .tint(session.category.color)
                        .frame(width: 120)
                }
            }
        }
        .padding()
        .background(session.category.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    var timeString: String {
        let remaining = session.plannedDuration - session.actualDuration
        let duration = remaining > 0 ? remaining : session.actualDuration
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

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                task.toggleComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)

                Label(task.category.rawValue, systemImage: task.category.icon)
                    .font(.caption)
                    .foregroundStyle(task.category.color)
            }

            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EnergyCheckIn: View {
    @Bindable var log: DailyLog

    var currentPeriod: (title: String, binding: Binding<Int?>) {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 12 {
            return ("Morning Energy", $log.morningEnergy)
        } else if hour < 17 {
            return ("Afternoon Energy", $log.afternoonEnergy)
        } else {
            return ("Evening Energy", $log.eveningEnergy)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Energy Check-in", systemImage: "bolt.fill")
                .font(.headline)

            let (title, binding) = currentPeriod

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            binding.wrappedValue = level
                        } label: {
                            Image(systemName: level <= (binding.wrappedValue ?? 0) ? "bolt.fill" : "bolt")
                                .foregroundStyle(level <= (binding.wrappedValue ?? 0) ? .orange : .gray)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    if let current = binding.wrappedValue {
                        Text(energyLabel(current))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func energyLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return ""
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [FocusSession.self, TaskItem.self, DailyLog.self], inMemory: true)
}
