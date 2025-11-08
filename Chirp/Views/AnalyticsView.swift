//
//  AnalyticsView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.windowSizeClass) private var sizeClass
    @Query(sort: \FocusSession.startTime, order: .reverse) private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingExportSheet = false

    enum TimePeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }

    var filteredSessions: [FocusSession] {
        let calendar = Calendar.current
        let now = Date()

        return sessions.filter { session in
            let daysDiff = calendar.dateComponents([.day], from: session.startTime, to: now).day ?? 0

            switch selectedPeriod {
            case .today:
                return calendar.isDateInToday(session.startTime)
            case .week:
                return daysDiff < 7
            case .month:
                return daysDiff < 30
            }
        }
    }

    var completedSessions: [FocusSession] {
        filteredSessions.filter { $0.endTime != nil }
    }

    var categoryBreakdown: [TaskCategory: TimeInterval] {
        var breakdown: [TaskCategory: TimeInterval] = [:]

        for session in completedSessions {
            breakdown[session.category, default: 0] += session.actualDuration
        }

        return breakdown
    }

    var totalDeepWork: TimeInterval {
        completedSessions.reduce(0) { $0 + $1.actualDuration }
    }

    var averageFocusQuality: Double {
        let qualities = completedSessions.compactMap { $0.focusQuality }
        guard !qualities.isEmpty else { return 0 }
        return Double(qualities.reduce(0, +)) / Double(qualities.count)
    }

    var totalInterruptions: Int {
        completedSessions.reduce(0) { $0 + $1.interruptionCount }
    }

    var completedTasksInPeriod: [TaskItem] {
        let calendar = Calendar.current
        let now = Date()

        return tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            let daysDiff = calendar.dateComponents([.day], from: completedAt, to: now).day ?? 0
            return daysDiff < selectedPeriod.days
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: sizeClass == .compact ? 16 : 24) {
                // Header
                VStack(spacing: sizeClass == .compact ? 4 : 8) {
                    Text("Analytics")
                        .font(sizeClass == .compact ? .title2 : .largeTitle)
                        .fontWeight(.bold)

                    if sizeClass == .full {
                        Text("Track your productivity patterns")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, sizeClass == .compact ? 60 : 40)

                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: sizeClass == .compact ? .infinity : 400)

                // Key Metrics
                if sizeClass == .compact {
                    // Compact mode: Show only essential metrics in vertical list
                    VStack(spacing: 12) {
                        CompactMetricRow(
                            icon: "clock.fill",
                            title: "Deep Work",
                            value: formatHours(totalDeepWork),
                            color: .blue
                        )
                        CompactMetricRow(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            value: "\(completedTasksInPeriod.count)",
                            color: .green
                        )
                        CompactMetricRow(
                            icon: "flame.fill",
                            title: "Sessions",
                            value: "\(completedSessions.count)",
                            color: .orange
                        )
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                        MetricCard(
                            icon: "clock.fill",
                            title: "Total Deep Work",
                            value: formatHours(totalDeepWork),
                            color: .blue
                        )

                        MetricCard(
                            icon: "checkmark.circle.fill",
                            title: "Tasks Completed",
                            value: "\(completedTasksInPeriod.count)",
                            color: .green
                        )

                        MetricCard(
                            icon: "flame.fill",
                            title: "Focus Sessions",
                            value: "\(completedSessions.count)",
                            color: .orange
                        )

                        MetricCard(
                            icon: "star.fill",
                            title: "Avg Focus Quality",
                            value: String(format: "%.1f/5", averageFocusQuality),
                            color: .yellow
                        )

                        MetricCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Interruptions",
                            value: "\(totalInterruptions)",
                            color: .red
                        )

                        MetricCard(
                            icon: "calendar",
                            title: "Days Active",
                            value: "\(uniqueActiveDays)",
                            color: .purple
                        )
                    }
                }

                // Category Balance (hide chart in compact, show list only)
                if !categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Time by Category")
                            .font(sizeClass == .compact ? .headline : .title2)
                            .fontWeight(.semibold)

                        if sizeClass == .full {
                            CategoryBalanceChart(breakdown: categoryBreakdown)
                        }

                        // Category List
                        VStack(spacing: 8) {
                            ForEach(categoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { category, duration in
                                HStack {
                                    Label(category.rawValue, systemImage: category.icon)
                                        .font(sizeClass == .compact ? .caption : .body)
                                        .foregroundStyle(category.color)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(formatHours(duration))
                                            .font(sizeClass == .compact ? .subheadline : .body)
                                            .fontWeight(.semibold)

                                        let percentage = (duration / totalDeepWork) * 100
                                        Text(String(format: "%.0f%%", percentage))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(sizeClass == .compact ? 10 : 16)
                                .background(category.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(sizeClass == .compact ? 12 : 16)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Daily Trend Chart (hide in compact mode)
                if sizeClass == .full && completedSessions.count > 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Deep Work Trend")
                            .font(.title2)
                            .fontWeight(.semibold)

                        DailyTrendChart(sessions: completedSessions, period: selectedPeriod)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Focus Quality Insights (hide in compact mode)
                if sizeClass == .full && !completedSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Focus Quality Insights")
                            .font(.title2)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            InsightRow(
                                icon: "star.fill",
                                title: "Average Focus Quality",
                                value: String(format: "%.1f/5", averageFocusQuality),
                                color: .yellow
                            )

                            if let bestCategory = bestFocusCategory {
                                InsightRow(
                                    icon: "trophy.fill",
                                    title: "Best Focus Category",
                                    value: bestCategory.rawValue,
                                    color: bestCategory.color
                                )
                            }

                            InsightRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Avg Interruptions per Session",
                                value: String(format: "%.1f", Double(totalInterruptions) / Double(completedSessions.count)),
                                color: .red
                            )
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Build in Public Export (hide in compact mode)
                if sizeClass == .full {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Share Your Progress")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("Generate Weekly Summary", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Text("Create a shareable summary for Twitter, LinkedIn, or your blog")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(sizeClass == .compact ? 12 : 16)
            .animation(.easeInOut(duration: 0.3), value: sizeClass)
        }
        .frame(maxWidth: sizeClass == .compact ? .infinity : 900)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingExportSheet) {
            WeeklySummarySheet(
                sessions: filteredSessions.filter { $0.endTime != nil },
                tasks: completedTasksInPeriod,
                categoryBreakdown: categoryBreakdown
            )
        }
    }

    var uniqueActiveDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(completedSessions.map { calendar.startOfDay(for: $0.startTime) })
        return uniqueDays.count
    }

    var bestFocusCategory: TaskCategory? {
        let categoryQuality = Dictionary(grouping: completedSessions) { $0.category }
            .mapValues { sessions in
                let qualities = sessions.compactMap { $0.focusQuality }
                guard !qualities.isEmpty else { return 0.0 }
                return Double(qualities.reduce(0, +)) / Double(qualities.count)
            }

        return categoryQuality.max(by: { $0.value < $1.value })?.key
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

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CompactMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CategoryBalanceChart: View {
    let breakdown: [TaskCategory: TimeInterval]

    var sortedCategories: [(category: TaskCategory, duration: TimeInterval)] {
        breakdown.sorted { $0.value > $1.value }
            .map { (category: $0.key, duration: $0.value) }
    }

    var total: TimeInterval {
        breakdown.values.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Horizontal stacked bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(sortedCategories, id: \.category) { item in
                        let percentage = item.duration / total
                        let width = geometry.size.width * percentage

                        Rectangle()
                            .fill(item.category.color)
                            .frame(width: width)
                    }
                }
            }
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Legend
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                ForEach(sortedCategories, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 8, height: 8)

                        Text(item.category.rawValue)
                            .font(.caption)

                        Spacer()
                    }
                }
            }
        }
    }
}

struct DailyTrendChart: View {
    let sessions: [FocusSession]
    let period: AnalyticsView.TimePeriod

    var dailyData: [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }

        return grouped.map { (date: $0.key, duration: $0.value.reduce(0) { $0 + $1.actualDuration }) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart {
            ForEach(dailyData, id: \.date) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Hours", data.duration / 3600)
                )
                .foregroundStyle(Color.blue.gradient)
            }
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                    }
                }
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(color)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WeeklySummarySheet: View {
    let sessions: [FocusSession]
    let tasks: [TaskItem]
    let categoryBreakdown: [TaskCategory: TimeInterval]

    @Environment(\.dismiss) private var dismiss

    var totalHours: TimeInterval {
        sessions.reduce(0) { $0 + $1.actualDuration }
    }

    var summaryText: String {
        let hours = Int(totalHours) / 3600
        let categories = categoryBreakdown.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key.rawValue }
            .joined(separator: ", ")

        return """
        📊 This Week's Progress

        ⏰ \(hours) hours of deep work
        ✅ \(tasks.count) tasks completed
        🔥 \(sessions.count) focus sessions

        Top focus areas: \(categories)

        Building in public 🚀
        """
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Weekly Summary")
                .font(.title)
                .fontWeight(.bold)

            Text(summaryText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button("Copy Text") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(summaryText, forType: .string)
                }
                .buttonStyle(.bordered)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 500)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [FocusSession.self, TaskItem.self], inMemory: true)
}
