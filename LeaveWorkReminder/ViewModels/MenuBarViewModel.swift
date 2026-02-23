import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var settings = AppSettings()
    @Published var isTestingAPI = false
    @Published var apiTestResult: String?
    @Published var apiTestSuccess = false
    @Published var isCheckingWalkingTime = false
    @Published var walkingTimeResult: String?

    private var monitor: ArrivalMonitorService!
    private var cancellables = Set<AnyCancellable>()
    private let apiService = SeoulBusAPIService()

    init() {
        self.monitor = ArrivalMonitorService(settings: settings)

        monitor.$monitorState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        monitor.$currentArrivalInfos
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        monitor.$lastUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        monitor.$todayLogs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        monitor.$calculatedWalkingMinutes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        if settings.isConfigured {
            monitor.startSchedule()
        }
    }

    // MARK: - Computed Properties

    var monitorState: MonitorState { monitor.monitorState }
    var currentArrivalInfos: [BusArrivalInfo] { monitor.currentArrivalInfos }
    var earliestArrivalInfo: BusArrivalInfo? { monitor.earliestArrivalInfo }
    var lastUpdated: Date? { monitor.lastUpdated }
    var todayLogs: [ArrivalMonitorService.LogEntry] { monitor.todayLogs }
    var calculatedWalkingMinutes: Int? { monitor.calculatedWalkingMinutes }
    var isPolling: Bool { monitor.isPolling }
    var totalLeadTimeMinutes: Int { monitor.totalLeadTimeMinutes }

    var menuBarIconName: String {
        monitorState.iconName
    }

    // MARK: - Actions

    func checkNow() async {
        await monitor.checkNow()
    }

    func startMonitoring() {
        monitor.startSchedule()
    }

    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    func testAPIConnection() async {
        isTestingAPI = true
        apiTestResult = nil

        do {
            let result = try await apiService.testConnection(
                serviceKey: settings.apiKey,
                arsId: settings.arsId
            )
            apiTestResult = result
            apiTestSuccess = true
        } catch {
            apiTestResult = error.localizedDescription
            apiTestSuccess = false
        }

        isTestingAPI = false
    }

    func checkWalkingTime() async {
        isCheckingWalkingTime = true
        walkingTimeResult = nil

        guard !settings.officeAddress.isEmpty else {
            walkingTimeResult = "사무실 주소를 입력해주세요"
            isCheckingWalkingTime = false
            return
        }

        // GPS 좌표가 캐시되어 있으면 사용, 없으면 정류소 조회
        var lat = settings.cachedGpsY
        var lon = settings.cachedGpsX
        if lat == 0 || lon == 0 {
            // 정류소 정보에서 좌표 가져오기
            guard !settings.arsId.isEmpty, !settings.apiKey.isEmpty else {
                walkingTimeResult = "정류소 번호와 API 키가 필요합니다"
                isCheckingWalkingTime = false
                return
            }
            do {
                let busNumber = settings.busNumbers.first ?? ""
                let info = try await apiService.getStationInfo(
                    serviceKey: settings.apiKey,
                    arsId: settings.arsId,
                    busNumber: busNumber
                )
                lat = info.gpsY
                lon = info.gpsX
            } catch {
                walkingTimeResult = "정류소 좌표 조회 실패: \(error.localizedDescription)"
                isCheckingWalkingTime = false
                return
            }
        }

        let minutes = await WalkingTimeService.calculateWalkingTime(
            from: settings.officeAddress,
            toLatitude: lat,
            toLongitude: lon
        )

        if let minutes = minutes {
            walkingTimeResult = "도보 약 \(minutes)분 (5분 올림 → \(TimeCalculator.roundUpToFiveMinutes(minutes))분)"
        } else {
            walkingTimeResult = "도보 시간 계산 실패 (주소를 확인해주세요)"
        }
        isCheckingWalkingTime = false
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("자동 실행 설정 실패: \(error.localizedDescription)")
        }
    }
}
