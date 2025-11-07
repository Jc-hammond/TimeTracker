//
//  FocusTimerView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]

    @State private var selectedSessionType: SessionType = .deepWork
    @State private var selectedCategory: TaskCategory = .building
    @State private var selectedTask: TaskItem?
    @State private var currentSession: FocusSession?

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    @State private var showingSessionComplete = false
    @State private var sessionFocusQuality = 3
    @State private var sessionEnergyLevel = 3
    @State private var sessionNotes = ""

    var activeSession: FocusSession? {
        sessions.first(where: { $0.isActive })
    }

    var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
            .sorted { $0.isDailyIntention && !$1.isDailyIntention }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Focus Session")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let session = activeSession {
                        Text("Started \(session.startTime, style: .relative) ago")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Ready to start your deep work")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 40)

                // Timer Display
                timerDisplay

                // Controls
                if activeSession != nil {
                    activeSessionControls
                } else {
                    sessionSetup
                }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .onAppear {
            if let active = activeSession {
                currentSession = active
                startTimer()
            }
        }
        .sheet(isPresented: $showingSessionComplete) {
            sessionCompleteSheet
        }
    }

    // MARK: - Timer Display
    var timerDisplay: some View {
        ZStack {
            // Progress Ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    selectedCategory.color.gradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            // Time Display
            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                if let session = activeSession {
                    Text(session.category.rawValue)
                        .font(.headline)
                        .foregroundStyle(session.category.color)

                    if let taskTitle = session.taskTitle {
                        Text(taskTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 200)
                    }

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
            }
        }
    }

    // MARK: - Session Setup (Before Starting)
    var sessionSetup: some View {
        VStack(spacing: 24) {
            // Session Type
            VStack(alignment: .leading, spacing: 12) {
                Label("Session Type", systemImage: "timer")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(SessionType.allCases) { type in
                        SessionTypeButton(
                            type: type,
                            isSelected: selectedSessionType == type
                        ) {
                            selectedSessionType = type
                        }
                    }
                }
            }

            // Category
            VStack(alignment: .leading, spacing: 12) {
                Label("Category", systemImage: "folder.fill")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(TaskCategory.allCases) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }

            // Task Selection (Optional)
            VStack(alignment: .leading, spacing: 12) {
                Label("Task (Optional)", systemImage: "checklist")
                    .font(.headline)

                if incompleteTasks.isEmpty {
                    Text("No tasks yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Menu {
                        Button("No task selected") {
                            selectedTask = nil
                        }

                        Divider()

                        ForEach(incompleteTasks) { task in
                            Button {
                                selectedTask = task
                            } label: {
                                Label {
                                    Text(task.title)
                                } icon: {
                                    Image(systemName: task.category.icon)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let task = selectedTask {
                                Label(task.title, systemImage: task.category.icon)
                                    .foregroundStyle(task.category.color)
                            } else {
                                Text("Select a task...")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Start Button
            Button {
                startSession()
            } label: {
                Label("Start Focus Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCategory.color.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Active Session Controls
    var activeSessionControls: some View {
        VStack(spacing: 16) {
            // Interruption Counter
            if let session = activeSession {
                HStack {
                    Label("Interruptions", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)

                    Spacer()

                    Text("\(session.interruptionCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Button {
                        session.addInterruption()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Control Buttons
            HStack(spacing: 12) {
                // Pause/Resume
                Button {
                    togglePause()
                } label: {
                    Label(
                        activeSession?.isPaused == true ? "Resume" : "Pause",
                        systemImage: activeSession?.isPaused == true ? "play.fill" : "pause.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Stop
                Button {
                    stopSession()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Session Complete Sheet
    var sessionCompleteSheet: some View {
        VStack(spacing: 24) {
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)

            if let session = currentSession {
                VStack(spacing: 8) {
                    Text("Duration: \(formatDuration(session.actualDuration))")
                        .font(.headline)

                    if session.interruptionCount > 0 {
                        Text("\(session.interruptionCount) interruption\(session.interruptionCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Focus Quality Rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus Quality")
                    .font(.headline)

                HStack {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            sessionFocusQuality = rating
                        } label: {
                            Image(systemName: rating <= sessionFocusQuality ? "star.fill" : "star")
                                .foregroundStyle(rating <= sessionFocusQuality ? .yellow : .gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Energy Level Rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Energy Level")
                    .font(.headline)

                HStack {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            sessionEnergyLevel = rating
                        } label: {
                            Image(systemName: rating <= sessionEnergyLevel ? "bolt.fill" : "bolt")
                                .foregroundStyle(rating <= sessionEnergyLevel ? .orange : .gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.headline)

                TextEditor(text: $sessionNotes)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Save Button
            Button {
                completeSession()
            } label: {
                Text("Save Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 500)
    }

    // MARK: - Computed Properties
    var progress: Double {
        guard let session = activeSession else { return 0 }
        return session.progress
    }

    var timeString: String {
        if let session = activeSession {
            let remaining = session.plannedDuration - session.actualDuration
            return remaining > 0 ? formatDuration(remaining) : formatDuration(session.actualDuration)
        }
        return formatDuration(selectedSessionType.defaultDuration)
    }

    // MARK: - Methods
    func startSession() {
        let session = FocusSession(
            sessionType: selectedSessionType,
            category: selectedCategory,
            taskTitle: selectedTask?.title
        )
        modelContext.insert(session)
        currentSession = session
        startTimer()
    }

    func togglePause() {
        guard let session = activeSession else { return }
        if session.isPaused {
            session.resume()
            startTimer()
        } else {
            session.pause()
            stopTimer()
        }
    }

    func stopSession() {
        stopTimer()
        showingSessionComplete = true
    }

    func completeSession() {
        currentSession?.complete(
            focusQuality: sessionFocusQuality,
            energyLevel: sessionEnergyLevel,
            notes: sessionNotes.isEmpty ? nil : sessionNotes
        )

        // Reset state
        currentSession = nil
        showingSessionComplete = false
        sessionFocusQuality = 3
        sessionEnergyLevel = 3
        sessionNotes = ""
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views
struct SessionTypeButton: View {
    let type: SessionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.rawValue)
                    .font(.headline)
                Text(formatDuration(type.defaultDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FocusTimerView()
        .modelContainer(for: [FocusSession.self, TaskItem.self], inMemory: true)
}
