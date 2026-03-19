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
