#!/usr/bin/env swift
import Foundation
// TimeCalculator 단위 테스트 (standalone, Xcode 불필요)

// --- TimeCalculator 로직 복사 (standalone 실행용) ---
enum Constants_Test {
    static let elevatorMinutes = 5
    static let bufferMinutes = 5
}

enum TimeCalculator_Test {
    static func roundUpToFiveMinutes(_ minutes: Int) -> Int {
        guard minutes > 0 else { return 0 }
        return ((minutes + 4) / 5) * 5
    }

    static func totalLeadTime(walkingMinutes: Int,
                               elevatorMinutes: Int = Constants_Test.elevatorMinutes,
                               bufferMinutes: Int = Constants_Test.bufferMinutes) -> Int {
        let roundedWalking = roundUpToFiveMinutes(walkingMinutes)
        return roundedWalking + elevatorMinutes + bufferMinutes
    }

    static func secondsToMinutes(_ seconds: Int) -> Int {
        seconds / 60
    }

    static func shouldNotify(busArrivalSeconds: Int, totalLeadTimeMinutes: Int) -> Bool {
        let arrivalMinutes = secondsToMinutes(busArrivalSeconds)
        return arrivalMinutes <= totalLeadTimeMinutes
    }
}

// --- 테스트 ---
var passed = 0
var failed = 0

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String) {
    if a == b {
        passed += 1
        print("  ✓ \(msg)")
    } else {
        failed += 1
        print("  ✗ \(msg) — expected \(b), got \(a)")
    }
}

func assertTrue(_ v: Bool, _ msg: String) {
    if v { passed += 1; print("  ✓ \(msg)") }
    else { failed += 1; print("  ✗ \(msg) — expected true") }
}

func assertFalse(_ v: Bool, _ msg: String) {
    if !v { passed += 1; print("  ✓ \(msg)") }
    else { failed += 1; print("  ✗ \(msg) — expected false") }
}

print("=== roundUpToFiveMinutes ===")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(0), 0, "0분 → 0분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(1), 5, "1분 → 5분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(3), 5, "3분 → 5분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(5), 5, "5분 → 5분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(6), 10, "6분 → 10분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(8), 10, "8분 → 10분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(10), 10, "10분 → 10분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(11), 15, "11분 → 15분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(12), 15, "12분 → 15분")
assertEqual(TimeCalculator_Test.roundUpToFiveMinutes(15), 15, "15분 → 15분")

print("\n=== totalLeadTime ===")
assertEqual(TimeCalculator_Test.totalLeadTime(walkingMinutes: 6), 20, "도보6분 → 20분")
assertEqual(TimeCalculator_Test.totalLeadTime(walkingMinutes: 12), 25, "도보12분 → 25분")
assertEqual(TimeCalculator_Test.totalLeadTime(walkingMinutes: 5), 15, "도보5분 → 15분")
assertEqual(TimeCalculator_Test.totalLeadTime(walkingMinutes: 0), 10, "도보0분 → 10분")

print("\n=== shouldNotify ===")
assertTrue(TimeCalculator_Test.shouldNotify(busArrivalSeconds: 20*60, totalLeadTimeMinutes: 20), "20분==20분 → 알림")
assertTrue(TimeCalculator_Test.shouldNotify(busArrivalSeconds: 15*60, totalLeadTimeMinutes: 20), "15분<20분 → 알림")
assertFalse(TimeCalculator_Test.shouldNotify(busArrivalSeconds: 25*60, totalLeadTimeMinutes: 20), "25분>20분 → 알림 안함")

print("\n=== secondsToMinutes ===")
assertEqual(TimeCalculator_Test.secondsToMinutes(180), 3, "180초 → 3분")
assertEqual(TimeCalculator_Test.secondsToMinutes(90), 1, "90초 → 1분")

print("\n=== 결과: \(passed)개 통과, \(failed)개 실패 ===")
if failed > 0 { exit(1) }
