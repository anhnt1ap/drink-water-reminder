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

    // MARK: - Test Helper

    #if DEBUG
    func setRecordsForTesting(_ newRecords: [DrinkRecord]) {
        records = newRecords
    }
    #endif
}
