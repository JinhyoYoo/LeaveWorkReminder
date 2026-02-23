import Foundation

enum TimeCalculator {
    /// 도보 시간을 5분 단위로 올림
    /// - 0분 → 0분, 1~5분 → 5분, 6~10분 → 10분, 11~15분 → 15분
    static func roundUpToFiveMinutes(_ minutes: Int) -> Int {
        guard minutes > 0 else { return 0 }
        return ((minutes + 4) / 5) * 5
    }

    /// 총 리드타임 계산
    /// = 올림된 도보 시간 + 엘리베이터 시간 + 여유 시간
    static func totalLeadTime(walkingMinutes: Int,
                               elevatorMinutes: Int = Constants.defaultElevatorMinutes,
                               bufferMinutes: Int = Constants.defaultBufferMinutes) -> Int {
        let roundedWalking = roundUpToFiveMinutes(walkingMinutes)
        return roundedWalking + elevatorMinutes + bufferMinutes
    }

    /// 버스 도착까지 남은 초를 분으로 변환
    static func secondsToMinutes(_ seconds: Int) -> Int {
        seconds / 60
    }

    /// 알림을 보내야 하는지 판단
    static func shouldNotify(busArrivalSeconds: Int, totalLeadTimeMinutes: Int) -> Bool {
        let arrivalMinutes = secondsToMinutes(busArrivalSeconds)
        return arrivalMinutes <= totalLeadTimeMinutes
    }

    /// 오늘의 특정 시:분이 이미 지났는지 확인
    static func hasTimePassed(hour: Int, minute: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        if currentHour > hour { return true }
        if currentHour == hour && currentMinute >= minute { return true }
        return false
    }

    /// 다음 체크 시간까지 남은 초 계산
    static func secondsUntil(hour: Int, minute: Int) -> TimeInterval {
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var targetDate = calendar.date(from: components) else { return 0 }

        // 이미 지났으면 내일로
        if targetDate <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }

        return targetDate.timeIntervalSince(now)
    }

    /// 주말인지 확인
    static func isWeekend() -> Bool {
        Calendar.current.isDateInWeekend(Date())
    }
}
