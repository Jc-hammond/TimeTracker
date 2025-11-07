//
//  DashboardView.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerManager: TimerManager

    @Query(sort: \Project.lastUsedAt, order: .reverse) private var recentProjects: [Project]
    @Query private var allTimeEntries: [TimeEntry]

    @Binding var showingProjectSheet: Bool
    @State private var selectedProject: Project?
    @State private var showingProjectPicker = false

    private var todayEntries: [TimeEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allTimeEntries.filter { entry in
            calendar.isDate(entry.startTime, inSameDayAs: today)
        }
    }

    private var todayDuration: TimeInterval {
        let completed = todayEntries.filter { !$0.isRunning }.reduce(0) { $0 + $1.duration }
        let active = timerManager.isTracking ? timerManager.elapsedTime : 0
        return completed + active
    }

    private var todayEarnings: Double {
        let completed = todayEntries.filter { !$0.isRunning }.reduce(0) { $0 + $1.earnings }
        let active = timerManager.currentEarnings
        return completed + active
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.generous) {
                // Greeting
                Text("\(Date().greeting), Connor")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignSystem.Spacing.generous)

                // Main Timer Card
                if timerManager.isTracking {
                    ActiveTimerCard()
                } else {
                    IdleTimerCard(
                        showingProjectPicker: $showingProjectPicker,
                        recentProjects: Array(recentProjects.prefix(3))
                    )
                }

                // Today's Summary
                TodaySummaryView(duration: todayDuration, earnings: todayEarnings)

                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.generous)
        }
        .sheet(isPresented: $showingProjectPicker) {
            ProjectPickerSheet(isPresented: $showingProjectPicker)
        }
    }
}

// MARK: - Active Timer Card
struct ActiveTimerCard: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.modelContext) private var modelContext

    @State private var isPulsing = false
    @State private var editedNotes: String = ""
    @FocusState private var notesFieldFocused: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.spacious) {
            // Status indicator
            HStack(spacing: DesignSystem.Spacing.close) {
                Circle()
                    .fill(timerManager.isPaused ? Color.orange : DesignSystem.Colors.accent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing && !timerManager.isPaused ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Text(timerManager.isPaused ? "PAUSED" : "TRACKING TIME")
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(timerManager.isPaused ? Color.orange : DesignSystem.Colors.accent)
                    .tracking(1.5)
            }
            .onAppear {
                isPulsing = true
                editedNotes = timerManager.currentNotes
            }

            // Timer display
            Text(timerManager.formattedTime)
                .font(DesignSystem.Typography.timerFont)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .monospacedDigit()

            // Project info
            if let project = timerManager.activeEntry?.project {
                VStack(spacing: DesignSystem.Spacing.comfortable) {
                    Text(project.displayName)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    // Editable notes field
                    TextField("Add notes...", text: $editedNotes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2...4)
                        .padding(DesignSystem.Spacing.close)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                        .focused($notesFieldFocused)
                        .onChange(of: editedNotes) { _, newValue in
                            timerManager.updateNotes(newValue)
                        }
                }
            }

            // Control buttons
            HStack(spacing: DesignSystem.Spacing.close) {
                // Pause/Resume button
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        Text(timerManager.isPaused ? "Resume" : "Pause")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.comfortable)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .hoverEffect(scale: 1.03)

                // Stop button
                Button(action: stopTimer) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.comfortable)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .hoverEffect(scale: 1.03)
            }
            .padding(.top, DesignSystem.Spacing.clear)
        }
        .padding(DesignSystem.Spacing.spacious)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (timerManager.isPaused ? Color.orange : DesignSystem.Colors.accent).opacity(0.3),
                            (timerManager.isPaused ? Color.orange : DesignSystem.Colors.accent).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )

        // Earnings counter
        if timerManager.currentEarnings > 0 && !timerManager.isPaused {
            Text("Earning: \(timerManager.currentEarnings.formattedCurrency) and counting...")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.success)
        }
    }

    private func togglePause() {
        withAnimation(DesignSystem.Animations.buttonPress) {
            if timerManager.isPaused {
                timerManager.resumeTimer()
            } else {
                timerManager.pauseTimer()
            }
        }
    }

    private func stopTimer() {
        withAnimation(DesignSystem.Animations.buttonPress) {
            _ = timerManager.stopTimer()
        }
    }
}

// MARK: - Idle Timer Card
struct IdleTimerCard: View {
    @Binding var showingProjectPicker: Bool
    let recentProjects: [Project]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.spacious) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.tertiaryText)

            Text("Start Tracking")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Button(action: { showingProjectPicker = true }) {
                Text("Click to begin")
                    .font(DesignSystem.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.comfortable)
                    .background(DesignSystem.Colors.accent.opacity(0.1))
                    .foregroundColor(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .hoverEffect(scale: 1.03)

            // Quick start
            if !recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                    Text("Quick Start:")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.top, DesignSystem.Spacing.clear)

                    ForEach(recentProjects) { project in
                        QuickStartButton(project: project)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.spacious)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: - Quick Start Button
struct QuickStartButton: View {
    @EnvironmentObject var timerManager: TimerManager

    let project: Project

    var body: some View {
        Button(action: startTracking) {
            HStack {
                if let client = project.client {
                    Rectangle()
                        .fill(client.color)
                        .frame(width: 4, height: 20)
                        .cornerRadius(2)
                }

                Text(project.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(.vertical, DesignSystem.Spacing.comfortable)
            .padding(.horizontal, DesignSystem.Spacing.clear)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .hoverEffect(scale: 1.02)
    }

    private func startTracking() {
        withAnimation(DesignSystem.Animations.buttonPress) {
            project.lastUsedAt = Date()
            timerManager.startTimer(for: project)
        }
    }
}

// MARK: - Today's Summary
struct TodaySummaryView: View {
    let duration: TimeInterval
    let earnings: Double

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.spacious) {
            SummaryItem(
                icon: "clock.fill",
                label: "Today",
                value: duration.formattedShort
            )

            Divider()
                .frame(height: 30)

            SummaryItem(
                icon: "dollarsign.circle.fill",
                label: "Earnings",
                value: earnings.formattedCurrency
            )
        }
        .padding(.vertical, DesignSystem.Spacing.clear)
    }
}

struct SummaryItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.close) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.tertiaryText)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)

                Text(value)
                    .font(DesignSystem.Typography.body.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
