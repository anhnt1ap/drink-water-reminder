# Drink Water Reminder — macOS Menu Bar App Design Spec

## Overview

A lightweight macOS menu bar app that reminds users to stand up and drink water using a countdown timer, system notifications, and a simple gamification system (points, streaks, goals). Built with pure SwiftUI, targeting macOS 13+.

## Goals

- Build a consistent hydration habit through gentle, non-intrusive reminders
- Provide motivation via points, streaks, and daily/weekly progress tracking
- Stay lightweight — always-visible in the menu bar, zero friction to use

## Architecture

**Approach:** Pure SwiftUI `MenuBarExtra` with `.window` style popover. No dock icon, no main window. The entire app lives in the menu bar.

**Target:** macOS 13+ (Ventura) — required for `MenuBarExtra`, SwiftUI `Charts`, `SMAppService`.

**Dependencies:** None. Pure SwiftUI + system frameworks.

**Key frameworks:** SwiftUI, Charts, UserNotifications, ServiceManagement.

## Menu Bar Icon & Popover

**Menu bar icon:** SF Symbol water drop (`drop.fill`) with countdown text beside it (e.g., `12:34`). When the timer reaches zero, the icon changes color (blue to red/orange).

**Popover layout (~300x450pt), top to bottom:**

1. **Header** — App name / greeting, current streak badge
2. **Countdown ring** — Circular progress indicator showing time until next drink, with minutes:seconds in the center
3. **Log Drink button** — Large, prominent tap target. Resets the timer, awards points, increments today's count
4. **Today's progress** — "6/8 glasses" with a horizontal progress bar
5. **Points display** — Today's points earned
6. **Navigation** — Tabs or segmented control: Home / Stats / Settings

## Timer & Notification System

**TimerManager** — A single `ObservableObject` owning countdown state.

- Stores `nextDrinkDate` (absolute `Date`) rather than a decrementing counter — survives app nap/sleep accurately
- `Timer.publish(every: 1)` drives the UI countdown display by computing `nextDrinkDate - now`
- When the timer reaches zero:
  1. Icon appearance changes (color shift)
  2. Fires a `UNUserNotificationCenter` local notification: "Time to stand up and drink water!"
  3. Timer stays at 00:00 until the user logs a drink (no auto-reset)
- Logging a drink resets the timer to the configured interval and dismisses the notification

**Background behavior:** `MenuBarExtra` apps stay alive in the background. If the Mac sleeps and wakes past the deadline, the app detects `nextDrinkDate` is in the past and immediately shows the overdue state.

**Notification permissions:** Requested on first launch. If denied, the app still works with icon-change-only fallback.

## Data Model & Persistence

All data stored locally via `UserDefaults` with `@AppStorage` / `Codable`.

### DrinkRecord

- `id: UUID`
- `timestamp: Date`
- `points: Int`

### UserStats (computed from DrinkRecord array)

- `dailyGoal: Int` (default 8)
- `currentStreak: Int` (consecutive days meeting goal)
- `longestStreak: Int`
- `totalLifetimePoints: Int`

### Settings

- `reminderInterval: Int` (15 / 30 / 45 / 60 minutes, default 30)
- `dailyGoal: Int` (default 8)
- `launchAtLogin: Bool`

### Data Flow

- `DrinkRecord` array is the source of truth — all stats are computed from it
- On each new day's first launch, check if yesterday's goal was met and update streak
- Records older than 90 days pruned to keep `UserDefaults` light

### Points System

- +10 points per drink logged
- +5 bonus if logged within 2 minutes of the reminder (rewarding promptness)
- Streak milestones: +50 at 7-day streak, +100 at 30-day streak

## Analytics — Stats View

**Daily Summary (top):**

- Glasses today: `6/8` with progress bar
- Points earned today
- Current streak
- Best streak

**Weekly Chart:**

- Bar chart: glasses per day, past 7 days
- Built with SwiftUI `Charts` framework (native, no external libs)
- X-axis: day labels (Mon–Sun)
- Y-axis: number of glasses
- Horizontal dashed line at daily goal level
- Bars colored: green (goal met) vs muted gray (not met)

## Settings View

- **Reminder interval** — Picker: 15 / 30 / 45 / 60 minutes (default 30)
- **Daily goal** — Stepper: 1–20 glasses (default 8)
- **Launch at login** — Toggle via `SMAppService`
- **About** — App version, tagline

Changes take effect immediately (timer resets to new interval on save).

## Visual Design

**Material flat / minimalist aesthetic:**

- **Color palette:** Monochrome base (white/dark gray) with accent blue (`#4A90D9`) for water drop, progress bars, active states
- **Typography:** SF Pro — regular for body, semibold for headings/numbers
- **Icons:** SF Symbols — `drop.fill`, `flame.fill` (streak), `chart.bar.fill` (stats), `gearshape` (settings)
- **Countdown ring:** Thin circular stroke (2pt), accent blue, large monospaced time in center
- **Progress bar:** Rounded capsule, accent blue fill on light gray track
- **Layout:** No borders or shadows — separated by spacing only, flat backgrounds
- **Dark mode:** Fully supported via SwiftUI adaptive colors
- **Animations:** Subtle only — progress bar fill transitions, countdown ring stroke animation. No bounces or spring effects.

## Project Structure

```
DrinkWaterReminder/
├── DrinkWaterReminderApp.swift      # @main, MenuBarExtra setup
├── Models/
│   ├── DrinkRecord.swift            # Drink log entry
│   ├── UserStats.swift              # Computed stats
│   └── Settings.swift               # User preferences
├── Managers/
│   ├── TimerManager.swift           # Countdown + notification logic
│   └── DataManager.swift            # Persistence, stats computation
├── Views/
│   ├── MainPopoverView.swift        # Root popover with tab navigation
│   ├── HomeView.swift               # Countdown ring, log button, progress
│   ├── StatsView.swift              # Daily summary + weekly chart
│   └── SettingsView.swift           # Interval, goal, launch-at-login
└── Assets.xcassets                   # App icon, accent color
```
