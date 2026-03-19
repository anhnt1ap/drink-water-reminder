import XCTest

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

    func testDrinksTodayMultiple() {
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
        for hour in 0..<8 {
            let time = calendar.date(byAdding: .hour, value: hour + 8, to: today)!
            records.append(DrinkRecord(timestamp: time, points: 10))
        }
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        for hour in 0..<8 {
            let time = calendar.date(byAdding: .hour, value: hour + 8, to: twoDaysAgo)!
            records.append(DrinkRecord(timestamp: time, points: 10))
        }
        dataManager.setRecordsForTesting(records)
        XCTAssertEqual(dataManager.currentStreak, 1)
    }

    func testLongestStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var records: [DrinkRecord] = []
        for dayOffset in (-14)...(-10) {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            for hour in 0..<8 {
                let time = calendar.date(byAdding: .hour, value: hour + 8, to: day)!
                records.append(DrinkRecord(timestamp: time, points: 10))
            }
        }
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

    func testPruneOldRecords() throws {
        let oldDate = Calendar.current.date(byAdding: .day, value: -91, to: Date())!
        let recentDate = Date().addingTimeInterval(-3600)
        let records = [
            DrinkRecord(timestamp: oldDate, points: 10),
            DrinkRecord(timestamp: recentDate, points: 10)
        ]
        dataManager.setRecordsForTesting(records)
        dataManager.pruneOldRecords()
        XCTAssertEqual(dataManager.records.count, 1)
        let remaining = try XCTUnwrap(dataManager.records.first)
        XCTAssertEqual(remaining.timestamp.timeIntervalSince1970,
                       recentDate.timeIntervalSince1970, accuracy: 1)
    }
}
