# macOS Native Architecture - Indie Dev Companion

## Tech Stack

### Core Technologies
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Data persistence (iOS 17+, macOS 14+)
- **Combine** - Reactive programming for timers and state management
- **AppKit Integration** - Menu bar app, notifications, calendar access

### macOS-Specific Features
- **Menu Bar App** - Quick access to start/stop focus sessions
- **Notification Center** - Session reminders, break alerts
- **Today Widget** - Show current focus session and daily progress
- **Keyboard Shortcuts** - Global hotkeys for common actions
- **Native macOS Design** - Follows Human Interface Guidelines

## App Architecture

### MVVM Pattern
```
Chirp/
├── Models/              # SwiftData models
│   ├── FocusSession.swift
│   ├── Task.swift
│   ├── DailyLog.swift
│   └── Category.swift
├── Views/               # SwiftUI views
│   ├── MainView.swift
│   ├── FocusTimer/
│   ├── TaskList/
│   ├── Analytics/
│   └── Settings/
├── ViewModels/          # Business logic
│   ├── FocusSessionViewModel.swift
│   └── TaskViewModel.swift
├── Services/            # Supporting services
│   ├── TimerService.swift
│   ├── NotificationService.swift
│   └── ExportService.swift
└── Utilities/           # Helpers
    └── Extensions.swift
```

## Data Models (SwiftData)

### FocusSession
- Tracks individual work sessions
- Linked to tasks and categories
- Records focus quality and interruptions

### Task
- Todo items with priorities
- Category assignment
- Time estimates vs actual
- Completion tracking

### DailyLog
- Daily energy and mood check-ins
- Wins, challenges, learnings
- Momentum score

### Category
- Pre-defined types (Building, Content, Marketing, etc.)
- Custom categories support
- Color coding and icons

## UI Components

### Main Window
- Sidebar navigation (Today, Tasks, Analytics, Settings)
- Main content area
- Bottom status bar (current session, daily progress)

### Menu Bar
- Quick start/stop timer
- Current session indicator
- Daily progress ring
- Quick access to tasks

### Focus Timer View
- Large, prominent timer display
- Session type selector (Deep Work, Sprint, Flow)
- Category picker
- Task selection
- Start/Pause/Stop controls
- Distraction counter

### Task List View
- Today's tasks (with "must-do" highlighting)
- Category filter tabs
- Quick add input
- Swipe to complete
- Task details sidebar

### Analytics View
- Weekly overview cards
- Category balance pie chart
- Focus quality trends
- Momentum streak
- Build in public export button

## macOS Integration

### Menu Bar App
- Lives in menu bar for quick access
- Dropdown shows current session
- Global keyboard shortcuts (⌘⇧F to start focus)

### Notifications
- Pre-session reminder (5 min before planned session)
- Break reminders (based on Cal Newport methodology)
- End of session summary
- Daily review prompt (Friday 4pm)

### Keyboard Shortcuts
- ⌘⇧F: Start focus session
- ⌘⇧P: Pause/Resume
- ⌘⇧S: Stop session
- ⌘T: Quick add task
- ⌘/: Show/hide main window

### Today Widget
- Shows current session timer
- Daily deep work hours
- Tasks completed count
- Quick start button

## Design System

### Colors (macOS Native)
- System accent color support
- Dark/Light mode automatic
- Category colors:
  - Building: Blue (#007AFF)
  - Content: Purple (#AF52DE)
  - Marketing: Orange (#FF9500)
  - Design: Pink (#FF2D55)
  - Customer: Green (#34C759)
  - Business: Gray (#8E8E93)
  - Learning: Teal (#5AC8FA)

### Typography
- SF Pro (macOS system font)
- Dynamic Type support
- Clear hierarchy

### Spacing
- 8pt grid system
- Consistent padding/margins
- Generous whitespace

## Performance Considerations

### Data Sync
- Local-first (SwiftData)
- iCloud sync optional
- Export to JSON/CSV

### Battery Optimization
- Efficient timer implementation
- Background task management
- Minimize wake-ups

### Memory Management
- Lazy loading of historical data
- Pagination for analytics
- Image asset optimization

## Development Phases

### Phase 1: Core Timer (Week 1-2)
- [ ] SwiftData models
- [ ] Focus timer view
- [ ] Basic task list
- [ ] Category system
- [ ] Start/stop/pause timer logic

### Phase 2: Menu Bar (Week 3)
- [ ] Menu bar app integration
- [ ] Global shortcuts
- [ ] Notifications
- [ ] Timer background running

### Phase 3: Analytics (Week 4)
- [ ] Daily/weekly stats
- [ ] Category balance charts
- [ ] Build in public export
- [ ] Weekly review view

### Phase 4: Polish (Week 5-6)
- [ ] Today widget
- [ ] Settings & preferences
- [ ] Keyboard shortcuts
- [ ] Onboarding flow
- [ ] App icon & branding

## Testing Strategy

- Unit tests for ViewModels
- SwiftData model tests
- UI tests for critical flows
- Manual testing on macOS 14+

## Distribution

### Beta (TestFlight)
- Invite indie hackers from community
- Collect feedback via in-app form
- Iterate quickly

### Release (Mac App Store)
- Submit for review
- Free tier with all core features
- Premium IAP for advanced features

---

**Updated:** 2025-11-07
**Status:** Ready to implement Phase 1
