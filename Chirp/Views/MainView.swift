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
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .focus: return "timer"
        case .tasks: return "checklist"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gear"
        }
    }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: NavigationItem = .today
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [TaskItem]
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size
            let sizeClass = WindowSizeClass.from(width: windowSize.width)
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Sidebar
                List(NavigationItem.allCases, selection: $selectedItem) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
                .onChange(of: selectedItem) { _, _ in
                    // Auto-hide sidebar in compact mode when navigation changes
                    if sizeClass == .compact {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            columnVisibility = .detailOnly
                        }
                    }
                }
                .onChange(of: sizeClass) { _, newSizeClass in
                    // Auto-hide sidebar in compact mode, show in full mode
                    withAnimation(.easeInOut(duration: 0.3)) {
                        columnVisibility = (newSizeClass == .full) ? .all : .detailOnly
                    }
                }
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
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
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.windowSize, windowSize)
                .environment(\.windowSizeClass, sizeClass)
            }
            .animation(.easeInOut(duration: 0.3), value: sizeClass)
            .task {
                // macOS 26 workaround: Initialize sidebar visibility with animation
                // This fixes the NavigationSplitView initialization bug in macOS Tahoe
                withAnimation {
                    columnVisibility = (sizeClass == .full) ? .all : .detailOnly
                }
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [FocusSession.self, TaskItem.self, DailyLog.self], inMemory: true)
}
