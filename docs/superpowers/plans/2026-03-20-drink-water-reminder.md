# Drink Water Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that reminds users to stand up and drink water with a countdown timer, system notifications, and gamification (points, streaks, daily/weekly goals).

**Architecture:** Pure SwiftUI `MenuBarExtra` with `.window` style popover. Data layer uses JSON file persistence for drink records, `@AppStorage` for settings. Single `TimerManager` drives the countdown and notifications. All stats computed from the `DrinkRecord` array.

**Tech Stack:** Swift, SwiftUI, Charts framework, UserNotifications, ServiceManagement, XcodeGen (project generation)

**Spec:** `docs/superpowers/specs/2026-03-19-drink-water-reminder-design.md`

---

## File Structure

```
DrinkWaterReminder/
├── project.yml                          # XcodeGen project definition
├── DrinkWaterReminder/
│   ├── DrinkWaterReminderApp.swift       # @main, MenuBarExtra setup, app lifecycle
│   ├── Info.plist                        # LSUIElement=YES (hide dock icon)
│   ├── DrinkWaterReminder.entitlements   # App Sandbox
│   ├── Models/
│   │   └── DrinkRecord.swift            # Codable drink log entry
│   ├── Managers/
│   │   ├── DataManager.swift            # JSON persistence, stats computation, pruning
│   │   └── TimerManager.swift           # Countdown timer, notification scheduling
│   ├── Views/
│   │   ├── MainPopoverView.swift        # Root popover with tab navigation
│   │   ├── HomeView.swift               # Countdown ring, log button, progress
│   │   ├── StatsView.swift              # Daily summary + weekly bar chart
│   │   └── SettingsView.swift           # Interval, goal, launch-at-login
│   └── Assets.xcassets/
│       ├── Contents.json
│       └── AccentColor.colorset/
│           └── Contents.json            # #4A90D9 accent blue
├── DrinkWaterReminderTests/
│   ├── DataManagerTests.swift           # Persistence, stats, streaks, points, pruning
│   └── TimerManagerTests.swift          # Timer state, overdue detection
```

---

### Task 1: Project Scaffold & Xcode Project

**Files:**
- Create: `project.yml`
- Create: `DrinkWaterReminder/Info.plist`
- Create: `DrinkWaterReminder/DrinkWaterReminder.entitlements`
- Create: `DrinkWaterReminder/Assets.xcassets/Contents.json`
- Create: `DrinkWaterReminder/Assets.xcassets/AccentColor.colorset/Contents.json`

- [ ] **Step 1: Install XcodeGen if needed**

Run: `which xcodegen || brew install xcodegen`

- [ ] **Step 2: Create project.yml**

```yaml
name: DrinkWaterReminder
options:
  bundleIdPrefix: com.apero
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true
settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"
targets:
  DrinkWaterReminder:
    type: application
    platform: macOS
    sources:
      - DrinkWaterReminder
    settings:
      base:
        INFOPLIST_FILE: DrinkWaterReminder/Info.plist
        CODE_SIGN_ENTITLEMENTS: DrinkWaterReminder/DrinkWaterReminder.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.apero.DrinkWaterReminder
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
  DrinkWaterReminderTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - DrinkWaterReminderTests
    dependencies:
      - target: DrinkWaterReminder
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.apero.DrinkWaterReminderTests
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/DrinkWaterReminder.app/Contents/MacOS/DrinkWaterReminder"
        BUNDLE_LOADER: "$(TEST_HOST)"
```

- [ ] **Step 3: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

`LSUIElement=YES` hides the app from the Dock — menu bar only.

- [ ] **Step 4: Create entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 5: Create Assets.xcassets**

Create `DrinkWaterReminder/Assets.xcassets/Contents.json`:
```json
{
  "info": { "version": 1, "author": "xcode" }
}
```

Create `DrinkWaterReminder/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": { "red": "0.290", "green": "0.565", "blue": "0.851", "alpha": "1.000" }
      },
      "idiom": "universal"
    }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

This defines accent blue `#4A90D9`.

- [ ] **Step 6: Create placeholder app entry point**

Create `DrinkWaterReminder/DrinkWaterReminderApp.swift`:
```swift
import SwiftUI

@main
struct DrinkWaterReminderApp: App {
    var body: some Scene {
        MenuBarExtra("Drink Water", systemImage: "drop.fill") {
            Text("Hello, Drink Water!")
                .frame(width: 300, height: 450)
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 7: Create test placeholder**

Create `DrinkWaterReminderTests/DataManagerTests.swift`:
```swift
import XCTest
@testable import DrinkWaterReminder

final class DataManagerTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 8: Generate Xcode project and verify build**

Run: `cd /Users/nguyentuananh/work/apero/seminar/drink-water-reminder && xcodegen generate`
Expected: `⚙️  Generating plists... ✅  Created project`

Run: `xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

Run: `xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
git add project.yml DrinkWaterReminder/ DrinkWaterReminderTests/
git commit -m "feat: scaffold Xcode project with MenuBarExtra entry point"
```

Note: Add `DrinkWaterReminder.xcodeproj` to `.gitignore` — it's generated by XcodeGen.

---

### Task 2: DrinkRecord Model

**Files:**
- Create: `DrinkWaterReminder/Models/DrinkRecord.swift`
- Modify: `DrinkWaterReminderTests/DataManagerTests.swift`

- [ ] **Step 1: Write failing test for DrinkRecord creation and JSON round-trip**

In `DrinkWaterReminderTests/DataManagerTests.swift`:
```swift
import XCTest
@testable import DrinkWaterReminder

final class DrinkRecordTests: XCTestCase {
    func testDrinkRecordCreation() {
        let record = DrinkRecord(timestamp: Date(), points: 10)
        XCTAssertEqual(record.points, 10)
        XCTAssertNotNil(record.id)
    }

    func testDrinkRecordCodable() throws {
        let original = DrinkRecord(timestamp: Date(timeIntervalSince1970: 1000000), points: 15)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DrinkRecord.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.points, original.points)
        XCTAssertEqual(decoded.timestamp, original.timestamp)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | grep -E '(error|FAIL|SUCCEED)'`
Expected: FAIL — `DrinkRecord` not found

- [ ] **Step 3: Implement DrinkRecord**

Create `DrinkWaterReminder/Models/DrinkRecord.swift`:
```swift
import Foundation

struct DrinkRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let points: Int

    init(id: UUID = UUID(), timestamp: Date = Date(), points: Int) {
        self.id = id
        self.timestamp = timestamp
        self.points = points
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Models/DrinkRecord.swift DrinkWaterReminderTests/DataManagerTests.swift
git commit -m "feat: add DrinkRecord model with Codable support"
```

---

### Task 3: DataManager — Persistence Layer

**Files:**
- Create: `DrinkWaterReminder/Managers/DataManager.swift`
- Modify: `DrinkWaterReminderTests/DataManagerTests.swift`

- [ ] **Step 1: Write failing tests for DataManager persistence**

Replace the placeholder `DataManagerTests` class in `DrinkWaterReminderTests/DataManagerTests.swift` (keep the `DrinkRecordTests` class from Task 2):
```swift
@MainActor
final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    var testDirectory: URL!

    override func setUp() {
        super.setUp()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        dataManager = DataManager(storageDirectory: testDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    func testInitialStateIsEmpty() {
        XCTAssertTrue(dataManager.records.isEmpty)
    }

    func testAddRecord() {
        let added = dataManager.addRecordIfAllowed(points: 10)
        XCTAssertTrue(added)
        XCTAssertEqual(dataManager.records.count, 1)
        XCTAssertEqual(dataManager.records.first?.points, 10)
    }

    func testPersistenceAcrossInstances() {
        dataManager.addRecordIfAllowed(points: 10)
        let secondManager = DataManager(storageDirectory: testDirectory)
        XCTAssertEqual(secondManager.records.count, 1)
    }

    func testCooldownPreventsRapidLogs() {
        dataManager.addRecordIfAllowed(points: 10)
        let added = dataManager.addRecordIfAllowed(points: 10)
        XCTAssertFalse(added)
        XCTAssertEqual(dataManager.records.count, 1)
    }

    func testPruneOldRecords() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -91, to: Date())!
        let recentDate = Date().addingTimeInterval(-3600)
        let records = [
            DrinkRecord(timestamp: oldDate, points: 10),
            DrinkRecord(timestamp: recentDate, points: 10)
        ]
        dataManager.setRecordsForTesting(records)
        dataManager.pruneOldRecords()
        XCTAssertEqual(dataManager.records.count, 1)
        XCTAssertEqual(dataManager.records.first?.timestamp.timeIntervalSince1970,
                       recentDate.timeIntervalSince1970, accuracy: 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | grep -E '(error|FAIL|SUCCEED)'`
Expected: FAIL — `DataManager` not found

- [ ] **Step 3: Implement DataManager persistence**

Create `DrinkWaterReminder/Managers/DataManager.swift`:
```swift
import Foundation

@MainActor
class DataManager: ObservableObject {
    @Published private(set) var records: [DrinkRecord] = []
    @Published var reminderInterval: Int {
        didSet { UserDefaults.standard.set(reminderInterval, forKey: "reminderInterval") }
    }
    @Published var dailyGoal: Int {
        didSet { UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal") }
    }

    private let storageDirectory: URL
    private let cooldownInterval: TimeInterval = 60 // 1 minute

    private var fileURL: URL {
        storageDirectory.appendingPathComponent("drink_records.json")
    }

    init(storageDirectory: URL? = nil) {
        self.reminderInterval = UserDefaults.standard.object(forKey: "reminderInterval") as? Int ?? 30
        self.dailyGoal = UserDefaults.standard.object(forKey: "dailyGoal") as? Int ?? 8
        if let dir = storageDirectory {
            self.storageDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.storageDirectory = appSupport.appendingPathComponent("DrinkWaterReminder")
        }
        ensureDirectoryExists()
        loadRecords()
        pruneOldRecords()
    }

    // MARK: - Persistence

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    private func loadRecords() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        records = (try? JSONDecoder().decode([DrinkRecord].self, from: data)) ?? []
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Add Records

    private func addRecord(points: Int) {
        let record = DrinkRecord(timestamp: Date(), points: points)
        records.append(record)
        saveRecords()
    }

    func addRecordIfAllowed(points: Int) -> Bool {
        if let last = records.last,
           Date().timeIntervalSince(last.timestamp) < cooldownInterval {
            return false
        }
        addRecord(points: points)
        return true
    }

    // MARK: - Pruning

    func pruneOldRecords() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let before = records.count
        records.removeAll { $0.timestamp < cutoff }
        if records.count != before {
            saveRecords()
        }
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Managers/DataManager.swift DrinkWaterReminderTests/DataManagerTests.swift
git commit -m "feat: add DataManager with JSON persistence and cooldown"
```

---

### Task 4: DataManager — Stats Computation

**Files:**
- Modify: `DrinkWaterReminder/Managers/DataManager.swift`
- Modify: `DrinkWaterReminderTests/DataManagerTests.swift`

- [ ] **Step 1: Write failing tests for stats computation**

Add to `DataManagerTests`:
```swift
func testDrinksToday() {
    dataManager.addRecord(points: 10)
    dataManager.addRecord(points: 10) // will fail cooldown — use direct append for test
    XCTAssertEqual(dataManager.drinksToday, 1)
}

func testDrinksTodayMultiple() {
    // Manually add records to bypass cooldown
    let today = Date()
    let records = [
        DrinkRecord(timestamp: today.addingTimeInterval(-3600), points: 10),
        DrinkRecord(timestamp: today.addingTimeInterval(-1800), points: 10),
        DrinkRecord(timestamp: today.addingTimeInterval(-600), points: 10)
    ]
    dataManager.setRecordsForTesting(records)
    XCTAssertEqual(dataManager.drinksToday, 3)
}

func testPointsToday() {
    let today = Date()
    let records = [
        DrinkRecord(timestamp: today.addingTimeInterval(-3600), points: 10),
        DrinkRecord(timestamp: today.addingTimeInterval(-1800), points: 15)
    ]
    dataManager.setRecordsForTesting(records)
    XCTAssertEqual(dataManager.pointsToday, 25)
}

func testStreakCalculation() {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var records: [DrinkRecord] = []
    // 3 consecutive days of meeting goal (8 drinks each)
    for dayOffset in [0, -1, -2] {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        for hour in 0..<8 {
            let time = calendar.date(byAdding: .hour, value: hour + 8, to: day)!
            records.append(DrinkRecord(timestamp: time, points: 10))
        }
    }
    dataManager.setRecordsForTesting(records)
    XCTAssertEqual(dataManager.currentStreak, 3)
}

func testStreakBreaksOnMissedDay() {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var records: [DrinkRecord] = []
    // Today: 8 drinks (goal met)
    for hour in 0..<8 {
        let time = calendar.date(byAdding: .hour, value: hour + 8, to: today)!
        records.append(DrinkRecord(timestamp: time, points: 10))
    }
    // Yesterday: missed (0 drinks)
    // 2 days ago: 8 drinks (goal met)
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
    for hour in 0..<8 {
        let time = calendar.date(byAdding: .hour, value: hour + 8, to: twoDaysAgo)!
        records.append(DrinkRecord(timestamp: time, points: 10))
    }
    dataManager.setRecordsForTesting(records)
    XCTAssertEqual(dataManager.currentStreak, 1) // only today counts
}

func testLongestStreak() {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var records: [DrinkRecord] = []
    // 5 days streak ending 10 days ago
    for dayOffset in (-14)...(-10) {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        for hour in 0..<8 {
            let time = calendar.date(byAdding: .hour, value: hour + 8, to: day)!
            records.append(DrinkRecord(timestamp: time, points: 10))
        }
    }
    // Current 2 day streak
    for dayOffset in [-1, 0] {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        for hour in 0..<8 {
            let time = calendar.date(byAdding: .hour, value: hour + 8, to: day)!
            records.append(DrinkRecord(timestamp: time, points: 10))
        }
    }
    dataManager.setRecordsForTesting(records)
    XCTAssertEqual(dataManager.currentStreak, 2)
    XCTAssertEqual(dataManager.longestStreak, 5)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | grep -E '(error|FAIL|SUCCEED)'`
Expected: FAIL — methods not found

- [ ] **Step 3: Add test helper and stats computed properties to DataManager**

Add to `DataManager`:
```swift
    // MARK: - Test Helper

    #if DEBUG
    func setRecordsForTesting(_ newRecords: [DrinkRecord]) {
        records = newRecords
    }
    #endif

    // MARK: - Computed Stats

    var drinksToday: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return records.filter { $0.timestamp >= startOfDay }.count
    }

    var pointsToday: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return records.filter { $0.timestamp >= startOfDay }.reduce(0) { $0 + $1.points }
    }

    var totalLifetimePoints: Int {
        records.reduce(0) { $0 + $1.points }
    }

    var currentStreak: Int {
        calculateStreak().current
    }

    var longestStreak: Int {
        calculateStreak().longest
    }

    private func calculateStreak() -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group records by day and count drinks per day
        var drinksPerDay: [Date: Int] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.timestamp)
            drinksPerDay[day, default: 0] += 1
        }

        // Walk backwards from today counting consecutive goal-met days
        var currentStreak = 0
        var longestStreak = 0
        var runningStreak = 0

        // Get all unique days sorted descending
        let allDays = drinksPerDay.keys.sorted(by: >)
        guard !allDays.isEmpty else { return (0, 0) }

        // Find the earliest day to check
        let earliestDay = allDays.last!
        let totalDays = calendar.dateComponents([.day], from: earliestDay, to: today).day! + 1

        var foundCurrentStreak = false

        for dayOffset in 0..<totalDays {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfThatDay = calendar.startOfDay(for: day)
            let count = drinksPerDay[startOfThatDay] ?? 0

            if count >= dailyGoal {
                runningStreak += 1
                if !foundCurrentStreak {
                    currentStreak = runningStreak
                }
            } else {
                if !foundCurrentStreak {
                    foundCurrentStreak = true
                    currentStreak = runningStreak
                }
                longestStreak = max(longestStreak, runningStreak)
                runningStreak = 0
            }
        }
        longestStreak = max(longestStreak, runningStreak)

        return (currentStreak, longestStreak)
    }

    /// Returns drink counts for the past 7 days (index 0 = 6 days ago, index 6 = today)
    var weeklyData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let count = records.filter {
                calendar.isDate($0.timestamp, inSameDayAs: day)
            }.count
            return (date: day, count: count)
        }
    }
} // end DataManager extension
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Managers/DataManager.swift DrinkWaterReminderTests/DataManagerTests.swift
git commit -m "feat: add stats computation — streaks, daily counts, weekly data"
```

---

### Task 5: DataManager — Points Calculation

**Files:**
- Modify: `DrinkWaterReminder/Managers/DataManager.swift`
- Modify: `DrinkWaterReminderTests/DataManagerTests.swift`

- [ ] **Step 1: Write failing tests for points logic**

Add to `DataManagerTests`:
```swift
func testBasePoints() {
    let points = DataManager.calculatePoints(
        reminderTime: nil,
        logTime: Date(),
        currentStreak: 0
    )
    XCTAssertEqual(points, 10)
}

func testBonusPointsForPromptResponse() {
    let reminderTime = Date()
    let logTime = reminderTime.addingTimeInterval(60) // 1 minute after reminder
    let points = DataManager.calculatePoints(
        reminderTime: reminderTime,
        logTime: logTime,
        currentStreak: 0
    )
    XCTAssertEqual(points, 15) // 10 base + 5 prompt bonus
}

func testNoBonusIfLateResponse() {
    let reminderTime = Date()
    let logTime = reminderTime.addingTimeInterval(180) // 3 minutes after
    let points = DataManager.calculatePoints(
        reminderTime: reminderTime,
        logTime: logTime,
        currentStreak: 0
    )
    XCTAssertEqual(points, 10) // no bonus
}

func testStreakMilestoneBonus7Days() {
    let points = DataManager.calculatePoints(
        reminderTime: nil,
        logTime: Date(),
        currentStreak: 6 // will become 7 after this drink if goal met
    )
    // Milestone checked elsewhere; base points only here
    XCTAssertEqual(points, 10)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | grep -E '(error|FAIL|SUCCEED)'`
Expected: FAIL

- [ ] **Step 3: Add static points calculation to DataManager**

Add to `DataManager`:
```swift
    // MARK: - Points Calculation

    static func calculatePoints(
        reminderTime: Date?,
        logTime: Date,
        currentStreak: Int
    ) -> Int {
        var points = 10 // base points

        // +5 bonus if logged within 2 minutes of reminder
        if let reminder = reminderTime,
           logTime.timeIntervalSince(reminder) <= 120 {
            points += 5
        }

        return points
    }

    /// Check and return milestone bonus after logging a drink
    func streakMilestoneBonus() -> Int {
        switch currentStreak {
        case 7: return 50
        case 30: return 100
        default: return 0
        }
    }

    /// Add milestone bonus points as a separate record
    func addMilestoneBonus(_ bonus: Int) {
        let record = DrinkRecord(timestamp: Date(), points: bonus)
        records.append(record)
        saveRecords()
    }
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Managers/DataManager.swift DrinkWaterReminderTests/DataManagerTests.swift
git commit -m "feat: add points calculation with prompt bonus"
```

---

### Task 6: TimerManager

**Files:**
- Create: `DrinkWaterReminder/Managers/TimerManager.swift`
- Create: `DrinkWaterReminderTests/TimerManagerTests.swift`

- [ ] **Step 1: Write failing tests for TimerManager**

Create `DrinkWaterReminderTests/TimerManagerTests.swift`:
```swift
import XCTest
@testable import DrinkWaterReminder

@MainActor
final class TimerManagerTests: XCTestCase {
    var timerManager: TimerManager!

    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
    }

    func testInitialState() {
        XCTAssertFalse(timerManager.isOverdue)
    }

    func testStartSetsNextDrinkDate() {
        timerManager.start(intervalMinutes: 30)
        XCTAssertNotNil(timerManager.nextDrinkDate)
        let expected = Date().addingTimeInterval(30 * 60)
        let diff = abs(timerManager.nextDrinkDate!.timeIntervalSince(expected))
        XCTAssertLessThan(diff, 2) // within 2 seconds
    }

    func testOverdueWhenPastDeadline() {
        timerManager.nextDrinkDate = Date().addingTimeInterval(-60) // 1 min ago
        timerManager.updateCountdown()
        XCTAssertTrue(timerManager.isOverdue)
    }

    func testResetAfterDrink() {
        timerManager.nextDrinkDate = Date().addingTimeInterval(-60)
        timerManager.updateCountdown()
        XCTAssertTrue(timerManager.isOverdue)

        timerManager.logDrink(intervalMinutes: 30)
        XCTAssertFalse(timerManager.isOverdue)
        XCTAssertNotNil(timerManager.nextDrinkDate)
    }

    func testCountdownString() {
        // Use 755 seconds (12:35) and allow ±1 second of drift
        timerManager.nextDrinkDate = Date().addingTimeInterval(755)
        timerManager.updateCountdown()
        let valid = ["12:35", "12:34"]
        XCTAssertTrue(valid.contains(timerManager.countdownString),
                      "Expected 12:35 or 12:34 but got \(timerManager.countdownString)")
    }

    func testCountdownStringWhenOverdue() {
        timerManager.nextDrinkDate = Date().addingTimeInterval(-60)
        timerManager.updateCountdown()
        XCTAssertEqual(timerManager.countdownString, "00:00")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | grep -E '(error|FAIL|SUCCEED)'`
Expected: FAIL

- [ ] **Step 3: Implement TimerManager**

Create `DrinkWaterReminder/Managers/TimerManager.swift`:
```swift
import Foundation
import UserNotifications
import Combine

@MainActor
class TimerManager: ObservableObject {
    @Published var nextDrinkDate: Date?
    @Published var isOverdue: Bool = false
    @Published var countdownString: String = "--:--"
    @Published var progress: Double = 1.0 // 1.0 = full, 0.0 = time's up

    private var timerCancellable: AnyCancellable?
    private var intervalMinutes: Int = 30

    func start(intervalMinutes: Int) {
        self.intervalMinutes = intervalMinutes
        nextDrinkDate = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
        isOverdue = false
        startTicking()
    }

    func logDrink(intervalMinutes: Int) {
        self.intervalMinutes = intervalMinutes
        nextDrinkDate = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
        isOverdue = false
        dismissNotification()
        updateCountdown()
    }

    func updateCountdown() {
        guard let target = nextDrinkDate else {
            countdownString = "--:--"
            progress = 1.0
            return
        }

        let remaining = target.timeIntervalSinceNow
        if remaining <= 0 {
            countdownString = "00:00"
            isOverdue = true
            progress = 0.0
        } else {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            countdownString = String(format: "%02d:%02d", minutes, seconds)
            isOverdue = false
            let totalInterval = TimeInterval(intervalMinutes * 60)
            progress = min(remaining / totalInterval, 1.0)
        }
    }

    private func startTicking() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCountdown()
                if self?.isOverdue == true {
                    self?.fireNotificationIfNeeded()
                }
            }
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private var notificationFired = false

    private func fireNotificationIfNeeded() {
        guard !notificationFired else { return }
        notificationFired = true

        let content = UNMutableNotificationContent()
        content.title = "Time to drink water! 💧"
        content.body = "Stand up, stretch, and drink a glass of water."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "drinkReminder",
            content: content,
            trigger: nil // fire immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func dismissNotification() {
        notificationFired = false
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["drinkReminder"]
        )
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Managers/TimerManager.swift DrinkWaterReminderTests/TimerManagerTests.swift
git commit -m "feat: add TimerManager with countdown and notifications"
```

---

### Task 7: HomeView — Countdown Ring, Log Button, Progress

**Files:**
- Create: `DrinkWaterReminder/Views/HomeView.swift`

- [ ] **Step 1: Implement HomeView**

Create `DrinkWaterReminder/Views/HomeView.swift`:
```swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var dataManager: DataManager

    private let accentBlue = Color(red: 0.290, green: 0.565, blue: 0.851)

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Drink Water")
                    .font(.headline)
                Spacer()
                if dataManager.currentStreak > 0 {
                    Label("\(dataManager.currentStreak)", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)

            // Countdown Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.isOverdue ? Color.red : accentBlue,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)

                Text(timerManager.countdownString)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(timerManager.isOverdue ? .red : .primary)
            }

            // Log Drink Button
            Button(action: logDrink) {
                Label("Log Drink", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentBlue)
            .padding(.horizontal)

            // Today's Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Today")
                        .font(.subheadline)
                    Spacer()
                    Text("\(dataManager.drinksToday)/\(dataManager.dailyGoal)")
                        .font(.subheadline.bold())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        Capsule()
                            .fill(accentBlue)
                            .frame(
                                width: geo.size.width * min(
                                    Double(dataManager.drinksToday) / Double(max(dataManager.dailyGoal, 1)),
                                    1.0
                                ),
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: dataManager.drinksToday)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)

            // Points Today
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(dataManager.pointsToday) points today")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func logDrink() {
        var points = DataManager.calculatePoints(
            reminderTime: timerManager.isOverdue ? timerManager.nextDrinkDate : nil,
            logTime: Date(),
            currentStreak: dataManager.currentStreak
        )
        let allowed = dataManager.addRecordIfAllowed(points: points)
        if allowed {
            // Check and award streak milestone bonus
            let milestone = dataManager.streakMilestoneBonus()
            if milestone > 0 {
                dataManager.addMilestoneBonus(milestone)
            }
            timerManager.logDrink(intervalMinutes: dataManager.reminderInterval)
        }
    }
}
```

- [ ] **Step 2: Regenerate project and verify build**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DrinkWaterReminder/Views/HomeView.swift
git commit -m "feat: add HomeView with countdown ring, log button, progress bar"
```

---

### Task 8: StatsView — Daily Summary & Weekly Chart

**Files:**
- Create: `DrinkWaterReminder/Views/StatsView.swift`

- [ ] **Step 1: Implement StatsView**

Create `DrinkWaterReminder/Views/StatsView.swift`:
```swift
import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var dataManager: DataManager

    private let accentBlue = Color(red: 0.290, green: 0.565, blue: 0.851)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Summary
                VStack(spacing: 12) {
                    Text("Today")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        StatCard(
                            icon: "drop.fill",
                            value: "\(dataManager.drinksToday)/\(dataManager.dailyGoal)",
                            label: "Glasses"
                        )
                        StatCard(
                            icon: "star.fill",
                            value: "\(dataManager.pointsToday)",
                            label: "Points"
                        )
                    }

                    HStack(spacing: 16) {
                        StatCard(
                            icon: "flame.fill",
                            value: "\(dataManager.currentStreak)",
                            label: "Streak"
                        )
                        StatCard(
                            icon: "trophy.fill",
                            value: "\(dataManager.longestStreak)",
                            label: "Best"
                        )
                    }
                }

                // Weekly Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.headline)

                    Chart {
                        ForEach(dataManager.weeklyData, id: \.date) { entry in
                            BarMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Glasses", entry.count)
                            )
                            .foregroundStyle(
                                entry.count >= dataManager.dailyGoal
                                    ? Color.green
                                    : Color.gray.opacity(0.4)
                            )
                            .cornerRadius(4)
                        }

                        RuleMark(y: .value("Goal", dataManager.dailyGoal))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .foregroundStyle(accentBlue.opacity(0.6))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 160)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 2: Regenerate project and verify build**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DrinkWaterReminder/Views/StatsView.swift
git commit -m "feat: add StatsView with daily summary and weekly bar chart"
```

---

### Task 9: SettingsView

**Files:**
- Create: `DrinkWaterReminder/Views/SettingsView.swift`

- [ ] **Step 1: Implement SettingsView**

Create `DrinkWaterReminder/Views/SettingsView.swift`:
```swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var timerManager: TimerManager
    @State private var launchAtLogin: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let intervalOptions = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)

            // Reminder Interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Reminder Interval")
                    .font(.subheadline.bold())
                Picker("", selection: $dataManager.reminderInterval) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: dataManager.reminderInterval) { _, newValue in
                    timerManager.logDrink(intervalMinutes: newValue)
                }
            }

            // Daily Goal
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Goal")
                    .font(.subheadline.bold())
                Stepper(
                    "\(dataManager.dailyGoal) glasses",
                    value: $dataManager.dailyGoal,
                    in: 1...20
                )
            }

            // Launch at Login
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }

            Spacer()

            // About
            VStack(spacing: 2) {
                Text("Drink Water Reminder v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Stay hydrated, stay healthy")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Failed to update login item: \(error.localizedDescription)"
            showError = true
            launchAtLogin = !enabled // revert toggle
        }
    }
}
```

- [ ] **Step 2: Regenerate project and verify build**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DrinkWaterReminder/Views/SettingsView.swift
git commit -m "feat: add SettingsView with interval, goal, launch-at-login"
```

---

### Task 10: MainPopoverView & App Wiring

**Files:**
- Create: `DrinkWaterReminder/Views/MainPopoverView.swift`
- Modify: `DrinkWaterReminder/DrinkWaterReminderApp.swift`

- [ ] **Step 1: Implement MainPopoverView and app entry point**

Both `TimerManager` and `DataManager` are owned by `DrinkWaterReminderApp` (the `@main` struct) and passed down. This ensures a single shared instance across the menu bar label and popover.

Create `DrinkWaterReminder/Views/MainPopoverView.swift`:
```swift
struct MainPopoverView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var timerManager: TimerManager
    @State private var selectedTab: PopoverTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(timerManager: timerManager, dataManager: dataManager)
                case .stats:
                    StatsView(dataManager: dataManager)
                case .settings:
                    SettingsView(dataManager: dataManager, timerManager: timerManager)
                }
            }
            .frame(height: 410)

            Divider()

            HStack {
                ForEach(PopoverTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 450)
        .onAppear {
            timerManager.requestNotificationPermission()
            if timerManager.nextDrinkDate == nil {
                timerManager.start(intervalMinutes: dataManager.reminderInterval)
            }
        }
    }
}
```

- [ ] **Step 2: Create app entry point**

Replace `DrinkWaterReminder/DrinkWaterReminderApp.swift`:
```swift
import SwiftUI

@main
struct DrinkWaterReminderApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(timerManager: timerManager, dataManager: dataManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(timerManager.isOverdue ? .red : .primary)
                Text(timerManager.countdownString)
                    .font(.system(.caption2, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 3: Regenerate project and verify build**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Run all tests**

Run: `xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -10`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DrinkWaterReminder/Views/MainPopoverView.swift DrinkWaterReminder/DrinkWaterReminderApp.swift
git commit -m "feat: add MainPopoverView with tabs and wire up app entry point"
```

---

### Task 11: Add .gitignore and Final Cleanup

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Create .gitignore**

```gitignore
# Xcode
*.xcodeproj/
*.xcworkspace/
xcuserdata/
DerivedData/
build/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# macOS
.DS_Store
```

- [ ] **Step 2: Run full build and test cycle**

Run: `xcodegen generate && xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminder -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

Run: `xcodebuild -project DrinkWaterReminder.xcodeproj -scheme DrinkWaterReminderTests -destination 'platform=macOS' test 2>&1 | tail -10`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Manual smoke test checklist**

Run the app via Xcode (`Cmd+R`) and verify:
- [ ] Water drop icon appears in menu bar with countdown
- [ ] Clicking icon opens popover with Home tab
- [ ] Countdown ring animates down
- [ ] Log Drink button works and resets timer
- [ ] Progress bar updates
- [ ] Stats tab shows daily summary and chart
- [ ] Settings tab shows interval picker, goal stepper, launch toggle
- [ ] When timer hits 0, icon turns red and notification fires
- [ ] Dark mode looks correct

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: add .gitignore for Xcode artifacts"
```

- [ ] **Step 5: Final push**

```bash
git push
```
