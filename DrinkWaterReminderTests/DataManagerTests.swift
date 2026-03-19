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
