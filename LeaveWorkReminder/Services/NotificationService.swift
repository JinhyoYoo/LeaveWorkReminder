import UserNotifications

enum NotificationService {
    static let categoryIdentifier = "BUS_ARRIVAL"
    static let confirmActionIdentifier = "CONFIRM"
    static let nextBusActionIdentifier = "NEXT_BUS"

    /// 알림 카테고리 등록 (앱 시작 시 호출)
    static func registerCategories() {
        let confirmAction = UNNotificationAction(
            identifier: confirmActionIdentifier,
            title: "확인",
            options: []
        )
        let nextBusAction = UNNotificationAction(
            identifier: nextBusActionIdentifier,
            title: "다음 버스 타자",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [confirmAction, nextBusAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func sendLeaveNotification(busNumber: String, arrivalMinutes: Int,
                                       walkingMinutes: Int, elevatorMinutes: Int,
                                       address: String, nextBusMessage: String) {
        let content = UNMutableNotificationContent()
        content.title = "퇴근 알리미 - 지금 출발하세요!"
        content.subtitle = "\(busNumber)번 버스 \(arrivalMinutes)분 후 도착"
        content.body = """
        도보 \(walkingMinutes)분 + 엘리베이터 \(elevatorMinutes)분
        현재 위치: \(address)
        다음 버스: \(nextBusMessage)
        """
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let request = UNNotificationRequest(
            identifier: "leaveWork-\(UUID().uuidString)",
            content: content,
            trigger: nil // 즉시
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 발송 실패: \(error.localizedDescription)")
            }
        }
    }
}
