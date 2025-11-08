//
//  ReportsView.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [TimeEntry]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingManualEntry = false
    @State private var showingCSVExport = false

    enum TimePeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    private var filteredEntries: [TimeEntry] {
        let calendar = Calendar.current
        let now = Date()

        return allEntries.filter { entry in
            guard !entry.isRunning else { return false }

            switch selectedPeriod {
            case .day:
                return calendar.isDateInToday(entry.startTime)
            case .week:
                guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                    return false
                }
                return interval.contains(entry.startTime)
            case .month:
                return calendar.isDate(entry.startTime, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var totalDuration: TimeInterval {
        filteredEntries.reduce(0) { $0 + $1.duration }
    }

    private var totalEarnings: Double {
        filteredEntries.reduce(0) { $0 + $1.earnings }
    }

    private var averageRate: Double {
        guard totalDuration > 0 else { return 0 }
        let hours = totalDuration / 3600
        return totalEarnings / hours
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.generous) {
                // Period selector and export buttons
                VStack(spacing: DesignSystem.Spacing.comfortable) {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Export button
                    HStack {
                        Button(action: { showingCSVExport = true }) {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(allEntries.isEmpty)

                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Summary cards
                HStack(spacing: DesignSystem.Spacing.clear) {
                    SummaryCard(
                        title: "Total Time",
                        value: totalDuration.formattedShort,
                        icon: "clock.fill",
                        color: .blue
                    )

                    SummaryCard(
                        title: "Total Earnings",
                        value: totalEarnings.formattedCurrency,
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )

                    SummaryCard(
                        title: "Avg. Rate",
                        value: averageRate.formattedCurrency + "/hr",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Chart
                if !filteredEntries.isEmpty {
                    ProjectBreakdownChart(entries: filteredEntries)
                        .padding(.horizontal)
                }

                // Entry list
                TimeEntryList(entries: filteredEntries)
                    .padding(.horizontal)
            }
            .padding(.bottom, DesignSystem.Spacing.generous)
        }
        .navigationTitle("Reports")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingManualEntry = true }) {
                    Label("Add Entry", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualTimeEntrySheet()
        }
        .sheet(isPresented: $showingCSVExport) {
            CSVExportSheet(entries: allEntries)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.comfortable) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))

                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tight) {
                Text(value)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.clear)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Project Breakdown Chart
struct ProjectBreakdownChart: View {
    let entries: [TimeEntry]

    private var projectData: [(project: String, duration: TimeInterval, color: Color)] {
        let grouped = Dictionary(grouping: entries) { $0.project }

        return grouped.compactMap { project, entries in
            guard let proj = project else { return nil }
            let duration = entries.reduce(0) { $0 + $1.duration }
            let color = proj.client?.color ?? DesignSystem.Colors.accent
            return (proj.displayName, duration, color)
        }
        .sorted { $0.duration > $1.duration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.clear) {
            Text("Time by Project")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Chart {
                ForEach(Array(projectData.enumerated()), id: \.offset) { index, data in
                    BarMark(
                        x: .value("Duration", data.duration / 3600),
                        y: .value("Project", data.project)
                    )
                    .foregroundStyle(data.color)
                }
            }
            .frame(height: max(200, CGFloat(projectData.count) * 50))
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.spacious)
        .cardStyle()
    }
}

// MARK: - Time Entry List
struct TimeEntryList: View {
    let entries: [TimeEntry]

    private var groupedEntries: [(date: Date, entries: [TimeEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.startTime)
        }

        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.clear) {
            Text("Recent Entries")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .padding(.bottom, DesignSystem.Spacing.close)

            VStack(spacing: DesignSystem.Spacing.comfortable) {
                ForEach(groupedEntries, id: \.date) { group in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.close) {
                        Text(group.date, style: .date)
                            .font(DesignSystem.Typography.callout.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal, DesignSystem.Spacing.clear)

                        ForEach(group.entries.sorted(by: { $0.startTime > $1.startTime })) { entry in
                            TimeEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
    }
}

struct TimeEntryRow: View {
    let entry: TimeEntry

    @State private var showingEditSheet = false

    var body: some View {
        Button(action: { showingEditSheet = true }) {
            HStack(spacing: DesignSystem.Spacing.comfortable) {
                if let client = entry.project?.client {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(client.color)
                        .frame(width: 4, height: 48)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let project = entry.project {
                        HStack(spacing: 6) {
                            Text(project.displayName)
                                .font(DesignSystem.Typography.body.weight(.medium))
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            // Archived indicator
                            if project.isArchived {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }
                    }

                    HStack(spacing: DesignSystem.Spacing.close) {
                        Text(entry.startTime, style: .time)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)

                        if !entry.notes.isEmpty {
                            Text("•")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)

                            Text(entry.notes)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.duration.formattedShort)
                        .font(DesignSystem.Typography.body.weight(.medium))
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text(entry.earnings.formattedCurrency)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.success)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.comfortable)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            EditTimeEntrySheet(entry: entry)
        }
    }
}
