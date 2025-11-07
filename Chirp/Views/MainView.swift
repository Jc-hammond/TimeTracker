//
//  MainView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable, Identifiable {
    case today = "Today"
    case focus = "Focus"
    case tasks = "Tasks"
    case analytics = "Analytics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .focus: return "timer"
        case .tasks: return "checklist"
        case .analytics: return "chart.bar.fill"
        }
    }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: NavigationItem = .today
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chirp")
                            .font(.headline)
                        Text("Indie Dev Companion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        } detail: {
            // Main content area
            Group {
                switch selectedItem {
                case .today:
                    TodayView()
                case .focus:
                    FocusTimerView()
                case .tasks:
                    TaskListView()
                case .analytics:
                    AnalyticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [FocusSession.self, TaskItem.self, DailyLog.self], inMemory: true)
}
