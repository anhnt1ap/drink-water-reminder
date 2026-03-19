import XCTest

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
        XCTAssertLessThan(diff, 2)
    }

    func testOverdueWhenPastDeadline() {
        timerManager.nextDrinkDate = Date().addingTimeInterval(-60)
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
