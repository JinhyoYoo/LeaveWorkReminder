import AppKit
import UserNotifications

/// 알림 액션 알림 이름 (Foundation NotificationCenter용)
extension Notification.Name {
    static let busNotificationConfirmed = Notification.Name("busNotificationConfirmed")
    static let busNotificationNextBus = Notification.Name("busNotificationNextBus")
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
            print("알림 권한: \(granted ? "허용" : "거부")")
        }
        // 알림 카테고리 등록 (확인 / 다음 버스 타자)
        NotificationService.registerCategories()
    }

    // 앱이 포그라운드일 때도 알림 표시 (alert 스타일)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // 사용자가 알림 버튼을 눌렀을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case NotificationService.confirmActionIdentifier:
            // "확인" → 모니터링 중지
            NotificationCenter.default.post(name: .busNotificationConfirmed, object: nil)

        case NotificationService.nextBusActionIdentifier:
            // "다음 버스 타자" → 다음 버스 대기
            NotificationCenter.default.post(name: .busNotificationNextBus, object: nil)

        case UNNotificationDefaultActionIdentifier:
            // 알림 자체를 클릭 (버튼 아님) → 확인과 동일하게 처리
            NotificationCenter.default.post(name: .busNotificationConfirmed, object: nil)

        default:
            break
        }

        completionHandler()
    }
}
