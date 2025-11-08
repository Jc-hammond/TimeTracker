//
//  TaskListView.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.windowSizeClass) private var sizeClass
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var newTaskTitle = ""
    @State private var newTaskCategory: TaskCategory = .building
    @State private var newTaskPriority: TaskPriority = .shouldDo
    @State private var selectedFilter: TaskCategory?
    @State private var showCompleted = false

    @State private var showError = false
    @State private var errorMessage = ""

    var filteredTasks: [TaskItem] {
        var tasks = allTasks

        // Filter by completion status
        if !showCompleted {
            tasks = tasks.filter { !$0.isCompleted }
        }

        // Filter by category
        if let filter = selectedFilter {
            tasks = tasks.filter { $0.category == filter }
        }

        return tasks
    }

    var dailyIntentions: [TaskItem] {
        allTasks.filter { $0.isDailyIntention && !$0.isCompleted }
    }

    var tasksByCategory: [TaskCategory: [TaskItem]] {
        Dictionary(grouping: filteredTasks) { $0.category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: sizeClass == .compact ? 16 : 24) {
                // Header
                VStack(spacing: sizeClass == .compact ? 4 : 8) {
                    Text("Tasks")
                        .font(sizeClass == .compact ? .title2 : .largeTitle)
                        .fontWeight(.bold)

                    Text("\(filteredTasks.filter { !$0.isCompleted }.count) active")
                        .font(sizeClass == .compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, sizeClass == .compact ? 60 : 40)

                // Quick Add Task
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Add a new task...", text: $newTaskTitle)
                            .textFieldStyle(.plain)
                            .font(sizeClass == .compact ? .subheadline : .body)
                            .onSubmit {
                                addTask()
                            }

                        Menu {
                            ForEach(TaskCategory.allCases) { category in
                                Button {
                                    newTaskCategory = category
                                } label: {
                                    Label(category.rawValue, systemImage: category.icon)
                                }
                            }
                        } label: {
                            if sizeClass == .compact {
                                Image(systemName: newTaskCategory.icon)
                                    .foregroundStyle(newTaskCategory.color)
                                    .frame(width: 32, height: 32)
                                    .background(newTaskCategory.color.opacity(0.15))
                                    .clipShape(Circle())
                            } else {
                                Label(newTaskCategory.rawValue, systemImage: newTaskCategory.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(newTaskCategory.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(newTaskCategory.color.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)

                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(sizeClass == .compact ? .title3 : .title2)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(newTaskTitle.isEmpty)
                    }
                    .padding(sizeClass == .compact ? 10 : 16)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: sizeClass == .compact ? 10 : 12))
                }

                // Daily Intentions
                if !dailyIntentions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(sizeClass == .compact ? "Must-Do" : "Today's Must-Do Items", systemImage: "star.fill")
                            .font(sizeClass == .compact ? .subheadline : .headline)
                            .foregroundStyle(.orange)

                        VStack(spacing: 8) {
                            ForEach(dailyIntentions) { task in
                                TaskRow(task: task, modelContext: modelContext)
                            }
                        }
                    }
                    .padding(sizeClass == .compact ? 12 : 16)
                    .background(Color.orange.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Category Filter (hide in compact mode)
                if sizeClass == .full {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedFilter == nil
                            ) {
                                selectedFilter = nil
                            }

                            ForEach(TaskCategory.allCases) { category in
                                let count = allTasks.filter { $0.category == category && !$0.isCompleted }.count
                                FilterChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    color: category.color,
                                    count: count,
                                    isSelected: selectedFilter == category
                                ) {
                                    selectedFilter = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Show Completed Toggle
                HStack {
                    Toggle("Show Completed", isOn: $showCompleted)
                        .toggleStyle(.switch)
                        .font(sizeClass == .compact ? .caption : .body)

                    Spacer()

                    if showCompleted {
                        Text("\(allTasks.filter { $0.isCompleted }.count) completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Tasks List
                if filteredTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text("No tasks yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("Add your first task to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    if selectedFilter != nil {
                        // Show filtered tasks
                        VStack(spacing: 8) {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task, modelContext: modelContext)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Group by category
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(TaskCategory.allCases) { category in
                                if let categoryTasks = tasksByCategory[category], !categoryTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label(category.rawValue, systemImage: category.icon)
                                            .font(.headline)
                                            .foregroundStyle(category.color)

                                        VStack(spacing: 8) {
                                            ForEach(categoryTasks) { task in
                                                TaskRow(task: task, modelContext: modelContext)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(sizeClass == .compact ? 12 : 16)
            .animation(.easeInOut(duration: 0.3), value: sizeClass)
        }
        .frame(maxWidth: sizeClass == .compact ? .infinity : 700)
        .frame(maxWidth: .infinity)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Validate title length
        guard newTaskTitle.count <= 500 else {
            errorMessage = "Task title is too long. Maximum 500 characters allowed."
            showError = true
            return
        }

        let task = TaskItem(
            title: newTaskTitle,
            category: newTaskCategory,
            priority: newTaskPriority
        )
        modelContext.insert(task)

        // Save to ensure persistence
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save task: \(error.localizedDescription)"
            showError = true
            modelContext.delete(task) // Rollback the insert
            return
        }

        // Reset form
        newTaskTitle = ""
        newTaskCategory = .building
        newTaskPriority = .shouldDo
    }
}

struct TaskRow: View {
    let task: TaskItem
    let modelContext: ModelContext

    @State private var isHovering = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                task.toggleComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(task.category.rawValue, systemImage: task.category.icon)
                        .font(.caption)
                        .foregroundStyle(task.category.color)

                    if task.isDailyIntention {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let estimated = task.estimatedMinutes {
                        Text("\(estimated) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Delete Button (shown on hover)
            if isHovering {
                Button {
                    deleteTask()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovering = hovering
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .contextMenu {
            Button {
                task.isDailyIntention.toggle()
                saveChanges()
            } label: {
                Label(
                    task.isDailyIntention ? "Remove from Must-Do" : "Mark as Must-Do",
                    systemImage: task.isDailyIntention ? "star.slash" : "star.fill"
                )
            }

            Divider()

            Menu {
                ForEach(TaskPriority.allCases) { priority in
                    Button {
                        task.priority = priority
                        saveChanges()
                    } label: {
                        HStack {
                            Text(priority.rawValue)
                            if task.priority == priority {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Change Priority", systemImage: "flag")
            }

            Menu {
                ForEach(TaskCategory.allCases) { category in
                    Button {
                        task.category = category
                        saveChanges()
                    } label: {
                        Label {
                            Text(category.rawValue)
                        } icon: {
                            Image(systemName: category.icon)
                        }
                    }
                }
            } label: {
                Label("Change Category", systemImage: "folder")
            }

            Divider()

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    func deleteTask() {
        modelContext.delete(task)

        // Save to ensure persistence
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            showError = true
        }
    }

    func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    var color: Color = .blue
    var count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                if let count = count {
                    Text("\(count)")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TaskListView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
