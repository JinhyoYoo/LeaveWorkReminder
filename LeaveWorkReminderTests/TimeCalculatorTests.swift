// TimeCalculator 단위 테스트
// Xcode 없이 실행: swift LeaveWorkReminderTests/TimeCalculatorTests.swift (standalone)
// Xcode 설치 시: swift test

#if canImport(XCTest)
import XCTest
@testable import LeaveWorkReminder

final class TimeCalculatorTests: XCTestCase {
    func testRoundUpToFiveMinutes() {
        XCTAssertEqual(TimeCalculator.roundUpToFiveMinutes(0), 0)
        XCTAssertEqual(TimeCalculator.roundUpToFiveMinutes(1), 5)
        XCTAssertEqual(TimeCalculator.roundUpToFiveMinutes(5), 5)
        XCTAssertEqual(TimeCalculator.roundUpToFiveMinutes(6), 10)
        XCTAssertEqual(TimeCalculator.roundUpToFiveMinutes(12), 15)
    }

    func testTotalLeadTime() {
        XCTAssertEqual(TimeCalculator.totalLeadTime(walkingMinutes: 6), 20)
        XCTAssertEqual(TimeCalculator.totalLeadTime(walkingMinutes: 12), 25)
        XCTAssertEqual(TimeCalculator.totalLeadTime(walkingMinutes: 5), 15)
        XCTAssertEqual(TimeCalculator.totalLeadTime(walkingMinutes: 0), 10)
    }

    func testShouldNotify() {
        XCTAssertTrue(TimeCalculator.shouldNotify(busArrivalSeconds: 20 * 60, totalLeadTimeMinutes: 20))
        XCTAssertTrue(TimeCalculator.shouldNotify(busArrivalSeconds: 15 * 60, totalLeadTimeMinutes: 20))
        XCTAssertFalse(TimeCalculator.shouldNotify(busArrivalSeconds: 25 * 60, totalLeadTimeMinutes: 20))
    }
}
#endif
