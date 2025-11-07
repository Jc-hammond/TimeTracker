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
        ZStack {
            // Ambient background gradient
            LinearGradient(
                colors: [
                    selectedCategory.color.opacity(0.08),
                    Color.clear,
                    selectedCategory.color.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: selectedCategory)

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 10) {
                    Text("Focus Session")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .tracking(0.5)

                    if let session = activeSession {
                        Text("Started \(session.startTime, style: .relative) ago")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Ready to start your deep work")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 40)

                // Controls or Timer Display based on state
                if activeSession != nil {
                    // Timer Display (prominent during session)
                    timerDisplay

                    // Active Session Controls
                    activeSessionControls
                } else {
                    // Timer Preview
                    timerDisplay
                    
                    // Session Setup
                    sessionSetup
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
        let isActive = activeSession != nil
        let size: CGFloat = 280
        let fontSize: CGFloat = 56
        let lineWidth: CGFloat = 20

        return ZStack {
            // Ambient glow background
            Circle()
                .fill(selectedCategory.color.opacity(0.15))
                .frame(width: size + 60, height: size + 60)
                .blur(radius: 40)

            // Progress Ring Background
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress Ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            selectedCategory.color,
                            selectedCategory.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: selectedCategory.color.opacity(0.5), radius: 12, x: 0, y: 4)
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Time Display
            VStack(spacing: isActive ? 12 : 8) {
                Text(timeString)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(1)

                if let session = activeSession {
                    Text(session.category.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(session.category.color)

                    if let taskTitle = session.taskTitle {
                        Text(taskTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 200)
                    }

                    if session.isPaused {
                        Text("Paused")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.orange.gradient)
                            .clipShape(Capsule())
                            .shadow(color: .orange.opacity(0.4), radius: 8, y: 2)
                    }
                } else {
                    Text(selectedCategory.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedCategory.color)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isActive)
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
    }

    // MARK: - Session Setup (Before Starting)
    var sessionSetup: some View {
        VStack(spacing: 20) {
            // Session Type
            VStack(alignment: .leading, spacing: 10) {
                Label("Session Type", systemImage: "timer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Picker("", selection: $selectedSessionType) {
                    ForEach(SessionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Category
            VStack(alignment: .leading, spacing: 10) {
                Label("Category", systemImage: "folder.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Picker("", selection: $selectedCategory) {
                    ForEach(TaskCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(height: 40)
            }

            // Task Selection (Optional)
            if !incompleteTasks.isEmpty {
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
                    HStack(spacing: 8) {
                        if let task = selectedTask {
                            Image(systemName: task.category.icon)
                                .foregroundStyle(task.category.color)
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        } else {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                            Text("Link Task")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Start Button
            Button {
                startSession()
            } label: {
                Label("Start Focus Session", systemImage: "play.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 28)
                    .background(
                        LinearGradient(
                            colors: [
                                selectedCategory.color,
                                selectedCategory.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: selectedCategory.color.opacity(0.4), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    // MARK: - Active Session Controls
    var activeSessionControls: some View {
        VStack(spacing: 20) {
            // Interruption Counter
            if let session = activeSession {
                HStack {
                    Label("Interruptions", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(session.interruptionCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Button {
                        session.addInterruption()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.15),
                            Color.orange.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }

            // Control Buttons
            HStack(spacing: 16) {
                // Pause/Resume
                Button {
                    togglePause()
                } label: {
                    Label(
                        activeSession?.isPaused == true ? "Resume" : "Pause",
                        systemImage: activeSession?.isPaused == true ? "play.fill" : "pause.fill"
                    )
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(0.2), radius: 8, y: 4)
                }
                .buttonStyle(.plain)

                // Complete
                Button {
                    stopSession()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .green.opacity(0.3), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    // MARK: - Session Complete Sheet
    var sessionCompleteSheet: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green.gradient)
                    .shadow(color: .green.opacity(0.3), radius: 12, y: 4)

                Text("Session Complete!")
                    .font(.system(.title, design: .rounded, weight: .bold))
            }

            if let session = currentSession {
                VStack(spacing: 12) {
                    HStack {
                        Label("Duration", systemImage: "clock.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(session.actualDuration))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    if session.interruptionCount > 0 {
                        HStack {
                            Label("Interruptions", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(session.interruptionCount)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // Focus Quality Rating
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus Quality")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            sessionFocusQuality = rating
                        } label: {
                            Image(systemName: rating <= sessionFocusQuality ? "star.fill" : "star")
                                .foregroundStyle(rating <= sessionFocusQuality ? .yellow : .gray.opacity(0.4))
                                .font(.title)
                                .shadow(color: rating <= sessionFocusQuality ? .yellow.opacity(0.3) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Energy Level Rating
            VStack(alignment: .leading, spacing: 12) {
                Text("Energy Level")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            sessionEnergyLevel = rating
                        } label: {
                            Image(systemName: rating <= sessionEnergyLevel ? "bolt.fill" : "bolt")
                                .foregroundStyle(rating <= sessionEnergyLevel ? .orange : .gray.opacity(0.4))
                                .font(.title)
                                .shadow(color: rating <= sessionEnergyLevel ? .orange.opacity(0.3) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)

                TextEditor(text: $sessionNotes)
                    .frame(height: 80)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }

            // Save Button
            Button {
                completeSession()
            } label: {
                Text("Save Session")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .blue.opacity(0.4), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(36)
        .frame(width: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Computed Properties
    var progress: Double {
        guard let session = activeSession else { return 0 }
        // Use elapsedTime to force update
        _ = elapsedTime
        return session.progress
    }

    var timeString: String {
        // Use elapsedTime to force SwiftUI to recalculate every second
        _ = elapsedTime

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

        // Save immediately to sync with menu bar
        try? modelContext.save()

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

        // Save immediately to sync with menu bar
        try? modelContext.save()
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

        // Save immediately to sync with menu bar
        try? modelContext.save()

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
