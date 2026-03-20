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
    @Published var notificationSound: String {
        didSet { UserDefaults.standard.set(notificationSound, forKey: "notificationSound") }
    }

    static let availableSounds = [
        "Default", "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop", "Purr",
        "Sosumi", "Submarine", "Tink"
    ]

    private let storageDirectory: URL
    private let cooldownInterval: TimeInterval = 60 // 1 minute

    private var fileURL: URL {
        storageDirectory.appendingPathComponent("drink_records.json")
    }

    init(storageDirectory: URL? = nil) {
        self.reminderInterval = UserDefaults.standard.object(forKey: "reminderInterval") as? Int ?? 30
        self.dailyGoal = UserDefaults.standard.object(forKey: "dailyGoal") as? Int ?? 8
        self.notificationSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
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

    func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Add Records

    private func addRecord(points: Int) {
        let record = DrinkRecord(timestamp: Date(), points: points)
        records.append(record)
        saveRecords()
    }

    @discardableResult
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

        var drinksPerDay: [Date: Int] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.timestamp)
            drinksPerDay[day, default: 0] += 1
        }

        var currentStreak = 0
        var longestStreak = 0
        var runningStreak = 0

        let allDays = drinksPerDay.keys.sorted(by: >)
        guard !allDays.isEmpty else { return (0, 0) }

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

    // MARK: - Points Calculation

    static func calculatePoints(
        reminderTime: Date?,
        logTime: Date,
        currentStreak: Int
    ) -> Int {
        var points = 10

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

    // MARK: - Test Helper

    #if DEBUG
    func setRecordsForTesting(_ newRecords: [DrinkRecord]) {
        records = newRecords
    }
    #endif
}
