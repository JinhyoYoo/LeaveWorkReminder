import Foundation
import AppKit
import Combine

@MainActor
final class ArrivalMonitorService: ObservableObject {
    @Published var monitorState: MonitorState = .idle
    @Published var currentArrivalInfos: [BusArrivalInfo] = []
    @Published var lastUpdated: Date?
    @Published var todayLogs: [LogEntry] = []
    @Published var calculatedWalkingMinutes: Int?

    private let apiService = SeoulBusAPIService()
    private let settings: AppSettings
    private var pollingTimer: Timer?
    private var scheduleTimer: Timer?
    private var hasNotifiedToday = false
    private var lastNotifiedDate: Date?

    /// "다음 버스 타자" 대기 상태: 이 시점 이후의 버스만 알림
    private var skipBusDeadline: Date?

    // Sleep/Wake 감지
    private var workspaceObservers: [NSObjectProtocol] = []
    // 알림 액션 옵저버
    private var notificationObservers: [NSObjectProtocol] = []

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
    }

    init(settings: AppSettings) {
        self.settings = settings
        setupSleepWakeHandling()
        setupNotificationActionHandling()
    }

    deinit {
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Public

    func startSchedule() {
        guard settings.isConfigured else {
            monitorState = .error("설정 미완료")
            return
        }

        // 주말 체크
        if settings.skipWeekends && TimeCalculator.isWeekend() {
            monitorState = .idle
            addLog("주말 - 모니터링 건너뜀")
            scheduleNextDayCheck()
            return
        }

        // 하루 리셋
        resetDailyIfNeeded()

        // 이미 체크 시간이 지났는지
        if TimeCalculator.hasTimePassed(hour: settings.checkHour, minute: settings.checkMinute) {
            startPolling()
        } else {
            monitorState = .waitingForCheckTime
            addLog("\(settings.checkHour):\(String(format: "%02d", settings.checkMinute)) 대기 중")
            scheduleCheckTime()
        }
    }

    func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        scheduleTimer?.invalidate()
        scheduleTimer = nil
        skipBusDeadline = nil
        monitorState = .idle
        addLog("모니터링 중단")
    }

    func checkNow() async {
        await fetchAndEvaluate()
    }

    var isPolling: Bool {
        pollingTimer?.isValid == true
    }

    /// 가장 빨리 도착하는 버스 정보
    var earliestArrivalInfo: BusArrivalInfo? {
        currentArrivalInfos
            .filter { $0.exps1 != nil && !$0.isServiceEnded }
            .min { ($0.exps1 ?? Int.max) < ($1.exps1 ?? Int.max) }
    }

    // MARK: - Notification Action Handling

    private func setupNotificationActionHandling() {
        // "확인" → 모니터링 중지
        let confirmObserver = NotificationCenter.default.addObserver(
            forName: .busNotificationConfirmed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleConfirmAction()
            }
        }
        notificationObservers.append(confirmObserver)

        // "다음 버스 타자" → 다음 버스 대기
        let nextBusObserver = NotificationCenter.default.addObserver(
            forName: .busNotificationNextBus,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleNextBusAction()
            }
        }
        notificationObservers.append(nextBusObserver)
    }

    private func handleConfirmAction() {
        addLog("사용자 확인 → 모니터링 중지")
        hasNotifiedToday = true
        skipBusDeadline = nil
        stopPollingOnly()
        monitorState = .notified
    }

    private func handleNextBusAction() {
        guard let earliest = earliestArrivalInfo, let exps1 = earliest.exps1 else {
            addLog("다음 버스 대기 → 도착 정보 없음, 폴링 계속")
            hasNotifiedToday = false
            return
        }

        // 현재 첫 번째 버스 도착 시점까지 알림 스킵
        let deadline = Date().addingTimeInterval(TimeInterval(exps1))
        skipBusDeadline = deadline
        hasNotifiedToday = false

        let deadlineFormatter = DateFormatter()
        deadlineFormatter.dateFormat = "HH:mm:ss"
        addLog("다음 버스 대기 → \(deadlineFormatter.string(from: deadline)) 이후 버스 알림")

        // 폴링이 멈춰있으면 재시작
        if !isPolling {
            monitorState = .polling
            pollingTimer = Timer.scheduledTimer(withTimeInterval: Constants.pollingIntervalSeconds, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.fetchAndEvaluate()
                }
            }
        }

        monitorState = .waitingForNextBus
    }

    // MARK: - Private

    private func scheduleCheckTime() {
        scheduleTimer?.invalidate()
        let seconds = TimeCalculator.secondsUntil(hour: settings.checkHour, minute: settings.checkMinute)
        guard seconds > 0 else {
            startPolling()
            return
        }

        scheduleTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.startPolling()
            }
        }
    }

    private func startPolling() {
        guard !hasNotifiedToday else {
            monitorState = .notified
            return
        }

        if skipBusDeadline != nil {
            monitorState = .waitingForNextBus
        } else {
            monitorState = .polling
        }
        addLog("모니터링 시작 (\(settings.busNumbers.joined(separator: ", "))번)")

        // 즉시 한 번 실행
        Task { await fetchAndEvaluate() }

        // 60초 간격 반복
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: Constants.pollingIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchAndEvaluate()
            }
        }
    }

    private func fetchAndEvaluate() async {
        do {
            // 정류소/노선 정보 확보
            try await ensureRouteInfos()

            guard settings.hasCachedRouteInfo else { return }

            // 각 버스별 도착 정보 조회
            var arrivalInfos: [BusArrivalInfo] = []
            for busNumber in settings.busNumbers {
                guard let cached = settings.cachedRoute(for: busNumber) else { continue }
                do {
                    let info = try await apiService.getArrivalInfo(
                        serviceKey: settings.apiKey,
                        stId: settings.cachedStId,
                        busRouteId: cached.busRouteId,
                        ord: cached.ord,
                        busNumber: busNumber
                    )
                    arrivalInfos.append(info)
                } catch {
                    addLog("\(busNumber)번 조회 실패: \(error.localizedDescription)")
                }
            }

            currentArrivalInfos = arrivalInfos
            lastUpdated = Date()

            // 모든 버스 운행 종료 체크
            let allEnded = !arrivalInfos.isEmpty && arrivalInfos.allSatisfy { $0.isServiceEnded }
            if allEnded {
                monitorState = .serviceEnded
                stopPollingOnly()
                addLog("전체 운행 종료")
                scheduleNextDayCheck()
                return
            }

            // 도보 시간 계산 (자동 모드 & 아직 미계산)
            if settings.walkingTimeMode == .auto && calculatedWalkingMinutes == nil {
                await calculateWalkingTime()
            }

            // 가장 빨리 오는 버스 기준으로 알림 판단
            let leadTime = totalLeadTimeMinutes
            if let earliest = earliestArrivalInfo,
               let exps1 = earliest.exps1,
               !hasNotifiedToday {

                let arrivalMinutes = TimeCalculator.secondsToMinutes(exps1)

                // "다음 버스 대기" 상태: skipBusDeadline 이전의 버스는 무시
                if let deadline = skipBusDeadline {
                    if Date() < deadline {
                        // 아직 스킵 대상 버스가 지나지 않음 → 알림 보류
                        addLog("\(earliest.busNumber)번 \(arrivalMinutes)분 후 도착 (다음 버스 대기 중)")
                        return
                    } else {
                        // 스킵 대상 버스가 이미 지남 → deadline 해제, 정상 판단
                        skipBusDeadline = nil
                        monitorState = .polling
                        addLog("이전 버스 통과 → 다음 버스 체크")
                    }
                }

                addLog("\(earliest.busNumber)번 \(arrivalMinutes)분 후 도착 (리드타임: \(leadTime)분)")

                if TimeCalculator.shouldNotify(busArrivalSeconds: exps1, totalLeadTimeMinutes: leadTime) {
                    sendNotification(arrivalInfo: earliest, arrivalMinutes: arrivalMinutes)
                }
            }
        } catch {
            monitorState = .error(error.localizedDescription)
            addLog("오류: \(error.localizedDescription)")
        }
    }

    private func ensureRouteInfos() async throws {
        guard !settings.hasCachedRouteInfo else { return }

        addLog("정류소 정보 조회 중...")
        let infos = try await apiService.getStationInfos(
            serviceKey: settings.apiKey,
            arsId: settings.arsId,
            busNumbers: settings.busNumbers
        )

        guard let first = infos.first else { return }
        settings.cachedStId = first.stId
        settings.cachedGpsX = first.gpsX
        settings.cachedGpsY = first.gpsY

        for info in infos {
            settings.setCachedRoute(busNumber: info.busNumber, busRouteId: info.busRouteId, ord: info.ord)
        }
        addLog("정류소 정보 확보: \(first.stationName) (\(infos.count)개 노선)")
    }

    private func calculateWalkingTime() async {
        guard settings.cachedGpsY != 0, settings.cachedGpsX != 0 else { return }

        let minutes = await WalkingTimeService.calculateWalkingTime(
            from: settings.officeAddress,
            toLatitude: settings.cachedGpsY,
            toLongitude: settings.cachedGpsX
        )

        if let minutes = minutes {
            calculatedWalkingMinutes = minutes
            addLog("도보 시간 계산: \(minutes)분")
        }
    }

    var totalLeadTimeMinutes: Int {
        let walkingMinutes: Int
        switch settings.walkingTimeMode {
        case .auto:
            walkingMinutes = calculatedWalkingMinutes ?? settings.manualWalkingMinutes
        case .manual:
            walkingMinutes = settings.manualWalkingMinutes
        }
        return TimeCalculator.totalLeadTime(
            walkingMinutes: walkingMinutes,
            elevatorMinutes: settings.elevatorMinutes,
            bufferMinutes: settings.bufferMinutes
        )
    }

    private func sendNotification(arrivalInfo: BusArrivalInfo, arrivalMinutes: Int) {
        let walkingMinutes: Int
        switch settings.walkingTimeMode {
        case .auto:
            walkingMinutes = TimeCalculator.roundUpToFiveMinutes(calculatedWalkingMinutes ?? settings.manualWalkingMinutes)
        case .manual:
            walkingMinutes = TimeCalculator.roundUpToFiveMinutes(settings.manualWalkingMinutes)
        }

        // 다른 버스 정보도 포함
        let otherBuses = currentArrivalInfos
            .filter { $0.busNumber != arrivalInfo.busNumber && !$0.isServiceEnded }
            .map { "\($0.busNumber)번: \($0.arrmsg1)" }
            .joined(separator: "\n")

        NotificationService.sendLeaveNotification(
            busNumber: arrivalInfo.busNumber,
            arrivalMinutes: arrivalMinutes,
            walkingMinutes: walkingMinutes,
            elevatorMinutes: settings.elevatorMinutes,
            address: settings.officeAddress,
            nextBusMessage: otherBuses.isEmpty ? arrivalInfo.arrmsg2 : otherBuses
        )

        // 알림 발송 후 대기 상태 (사용자가 버튼을 누를 때까지)
        hasNotifiedToday = true
        lastNotifiedDate = Date()
        monitorState = .notified
        addLog("알림 발송! (\(arrivalInfo.busNumber)번 기준) - 사용자 응답 대기")
    }

    private func stopPollingOnly() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func scheduleNextDayCheck() {
        scheduleTimer?.invalidate()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 0
        components.minute = 1

        if let tomorrow = calendar.date(from: components) {
            let interval = tomorrow.timeIntervalSince(Date())
            scheduleTimer = Timer.scheduledTimer(withTimeInterval: max(interval, 60), repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.startSchedule()
                }
            }
        }
    }

    private func resetDailyIfNeeded() {
        let calendar = Calendar.current
        if let lastDate = lastNotifiedDate, !calendar.isDateInToday(lastDate) {
            hasNotifiedToday = false
            skipBusDeadline = nil
            todayLogs.removeAll()
        }
        if lastNotifiedDate == nil {
            hasNotifiedToday = false
        }
    }

    private func addLog(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message)
        todayLogs.append(entry)
        if todayLogs.count > 50 {
            todayLogs.removeFirst()
        }
    }

    // MARK: - Sleep/Wake

    private func setupSleepWakeHandling() {
        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.addLog("Mac 깨어남 - 스케줄 재확인")
                self?.startSchedule()
            }
        }
        workspaceObservers.append(wakeObserver)
    }
}
