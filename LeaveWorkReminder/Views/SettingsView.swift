import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        TabView {
            GeneralTab(viewModel: viewModel)
                .tabItem {
                    Label("일반", systemImage: "gear")
                }

            APITab(viewModel: viewModel)
                .tabItem {
                    Label("API", systemImage: "network")
                }
        }
        .frame(width: 520, height: 540)
    }
}

// MARK: - 일반 탭

private struct GeneralTab: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var newBusNumber = ""

    var body: some View {
        Form {
            Section("정류소 설정") {
                HStack {
                    TextField("정류소 번호 (arsId)", text: $viewModel.settings.arsId)
                        .textFieldStyle(.roundedBorder)
                    Button("노선 확인") {
                        RouteListWindowController.shared.showRoutes(
                            apiKey: viewModel.settings.apiKey,
                            arsId: viewModel.settings.arsId
                        ) { selectedBusNumber in
                            viewModel.settings.addBusNumber(selectedBusNumber)
                        }
                    }
                    .disabled(viewModel.settings.arsId.isEmpty || viewModel.settings.apiKey.isEmpty)
                }

                // 버스 추가 입력
                HStack {
                    TextField("버스 번호", text: $newBusNumber)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addBus() }
                    Button("추가") { addBus() }
                        .disabled(newBusNumber.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // 등록된 버스 목록
                let buses = viewModel.settings.busNumbers
                if !buses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(buses, id: \.self) { bus in
                            HStack {
                                Image(systemName: "bus.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text("\(bus)번")
                                    .font(.callout)
                                Spacer()
                                Button {
                                    viewModel.settings.removeBusNumber(bus)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(buses.count <= 1)
                                .opacity(buses.count <= 1 ? 0.3 : 1)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            Section("모니터링 시작 시간") {
                HStack {
                    Picker("시", selection: $viewModel.settings.checkHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)시").tag(hour)
                        }
                    }
                    .frame(width: 120)

                    Picker("분", selection: $viewModel.settings.checkMinute) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                            Text("\(minute)분").tag(minute)
                        }
                    }
                    .frame(width: 120)
                }
            }

            Section("도보 / 이동 시간") {
                TextField("사무실 주소", text: $viewModel.settings.officeAddress)
                    .textFieldStyle(.roundedBorder)

                Picker("도보 시간 계산", selection: $viewModel.settings.walkingTimeMode) {
                    ForEach(WalkingTimeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.settings.walkingTimeMode == .manual {
                    Stepper(
                        "도보 시간: \(viewModel.settings.manualWalkingMinutes)분",
                        value: $viewModel.settings.manualWalkingMinutes,
                        in: 1...60
                    )
                }

                if viewModel.settings.walkingTimeMode == .auto {
                    HStack {
                        if let walkingTime = viewModel.calculatedWalkingMinutes {
                            Text("자동 계산: \(walkingTime)분")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("미계산")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            Task { await viewModel.checkWalkingTime() }
                        } label: {
                            HStack(spacing: 4) {
                                if viewModel.isCheckingWalkingTime {
                                    ProgressView()
                                        .controlSize(.mini)
                                }
                                Text("도보 시간 체크")
                            }
                        }
                        .controlSize(.small)
                        .disabled(viewModel.isCheckingWalkingTime || viewModel.settings.officeAddress.isEmpty)
                    }

                    if let result = viewModel.walkingTimeResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("실패") ? .red : .green)
                    }
                }

                Stepper(
                    "엘리베이터: \(viewModel.settings.elevatorMinutes)분",
                    value: $viewModel.settings.elevatorMinutes,
                    in: 0...30
                )

                Stepper(
                    "여유 시간: \(viewModel.settings.bufferMinutes)분",
                    value: $viewModel.settings.bufferMinutes,
                    in: 0...30
                )

                let leadTime = viewModel.totalLeadTimeMinutes
                Text("총 리드타임: \(leadTime)분 (도보 + 엘리베이터 \(viewModel.settings.elevatorMinutes)분 + 여유 \(viewModel.settings.bufferMinutes)분)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Section("옵션") {
                Toggle("주말 건너뛰기", isOn: $viewModel.settings.skipWeekends)
                Toggle("로그인 시 자동 실행", isOn: $viewModel.settings.launchAtLogin)
                    .onChange(of: viewModel.settings.launchAtLogin) { _, newValue in
                        viewModel.updateLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addBus() {
        let trimmed = newBusNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.settings.addBusNumber(trimmed)
        newBusNumber = ""
    }
}

// MARK: - API 탭

private struct APITab: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var isEditingKey = false
    @State private var editingKeyText = ""

    var body: some View {
        Form {
            Section("공공데이터포털 API 키") {
                if isEditingKey {
                    HStack {
                        SecureField("API 키를 입력하세요", text: $editingKeyText)
                            .textFieldStyle(.roundedBorder)
                        Button("저장") {
                            viewModel.settings.apiKey = editingKeyText
                            isEditingKey = false
                        }
                        Button("취소") {
                            editingKeyText = viewModel.settings.apiKey
                            isEditingKey = false
                        }
                    }
                } else {
                    HStack {
                        if viewModel.settings.apiKey.isEmpty {
                            Text("등록된 키 없음")
                                .foregroundStyle(.secondary)
                        } else {
                            let key = viewModel.settings.apiKey
                            let masked = String(key.prefix(8)) + "••••••••" + String(key.suffix(4))
                            Text(masked)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(viewModel.settings.apiKey.isEmpty ? "등록" : "수정") {
                            editingKeyText = viewModel.settings.apiKey
                            isEditingKey = true
                        }
                    }
                }

                Button {
                    GuideWindowController.shared.showGuide()
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("API 키 발급 가이드")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            Section("연결 테스트") {
                HStack {
                    Button("API 연결 테스트") {
                        Task { await viewModel.testAPIConnection() }
                    }
                    .disabled(viewModel.settings.apiKey.isEmpty)

                    if viewModel.isTestingAPI {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let result = viewModel.apiTestResult {
                    Text(result)
                        .foregroundStyle(viewModel.apiTestSuccess ? .green : .red)
                        .font(.caption)
                }
            }

            Section("캐시") {
                if viewModel.settings.hasCachedRouteInfo {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("stId: \(viewModel.settings.cachedStId)")
                        let routeMap = viewModel.settings.routeMap
                        ForEach(Array(routeMap.keys.sorted()), id: \.self) { bus in
                            if let route = routeMap[bus] {
                                Text("\(bus)번 → routeId: \(route.busRouteId), ord: \(route.ord)")
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button("캐시 초기화") {
                        viewModel.settings.clearCache()
                    }
                } else {
                    Text("캐시된 정류소 정보 없음")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 가이드 별도 윈도우

final class GuideWindowController {
    static let shared = GuideWindowController()
    private var window: NSWindow?

    func showGuide() {
        // 이미 열려있으면 앞으로 가져오기
        if let window = window, window.isVisible {
            window.orderFrontRegardless()
            return
        }

        let guideView = GuideContentView {
            self.window?.close()
        }

        let hostingView = NSHostingView(rootView: guideView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: 480)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "API 키 발급 가이드"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.level = .floating

        // 설정창 옆에 배치
        if let settingsWindow = NSApp.windows.first(where: {
            $0.title.contains("Settings") || $0.title.contains("설정") ||
            $0.identifier?.rawValue.contains("settings") == true
        }) {
            let settingsFrame = settingsWindow.frame
            let guideOrigin = NSPoint(
                x: settingsFrame.maxX + 12,
                y: settingsFrame.origin.y + settingsFrame.height - 480
            )
            window.setFrameOrigin(guideOrigin)
        } else {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}

// MARK: - 가이드 콘텐츠 뷰

private struct GuideContentView: View {
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                guideStep(1, "data.go.kr 회원가입 및 로그인")
                guideStep(2, "검색창에 아래 2개 API를 각각 검색 후 활용신청")

                VStack(alignment: .leading, spacing: 3) {
                    guideBullet("서울특별시_정류소정보조회 서비스")
                    guideBullet("서울특별시_버스도착정보조회 서비스")
                }
                .padding(.leading, 16)

                guideStep(3, "활용 목적에 \"개인 프로젝트\" 입력")
                guideStep(4, "승인 후 (즉시~2시간)")

                VStack(alignment: .leading, spacing: 3) {
                    guideBullet("마이페이지 → 활용신청 현황")
                    guideBullet("일반 인증키(Encoding) 복사")
                    guideBullet("API 탭에서 '등록' 버튼 클릭 후 붙여넣기")
                }
                .padding(.leading, 16)

                guideStep(5, "\"API 연결 테스트\" 버튼으로 확인")

                Divider()
                    .padding(.vertical, 4)

                // 키 동기화 주의사항
                VStack(alignment: .leading, spacing: 4) {
                    Label("인증키 동기화 안내", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)

                    Text("data.go.kr에서 키 승인 후에도 실제 API 서버(ws.bus.go.kr)에 동기화되기까지 시간이 걸릴 수 있습니다.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("인증키 동기화는 매주 월요일에 진행됩니다. 승인 후 가장 가까운 월요일까지 대기가 필요할 수 있습니다.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("키 재발급 시 동기화가 리셋되므로 재발급은 삼가주세요.")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.8))
                }
                .padding(8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(6)

                Divider()
                    .padding(.vertical, 4)

                Text("두 API 모두 같은 인증키를 사용합니다.\nEncoding/Decoding 어느 쪽이든 입력 가능합니다.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Link("data.go.kr에서 키 발급하기",
                     destination: URL(string: "https://www.data.go.kr")!)
                    .font(.caption)
            }
            .padding(16)
        }
    }

    private func guideStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(number).")
                .fontWeight(.semibold)
                .frame(width: 16, alignment: .trailing)
            Text(text)
        }
        .font(.caption)
    }

    private func guideBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\u{2022}")
            Text(text)
                .textSelection(.enabled)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - 노선 확인 윈도우

@MainActor
final class RouteListWindowController {
    static let shared = RouteListWindowController()
    private var window: NSWindow?

    func showRoutes(apiKey: String, arsId: String, onSelect: @escaping (String) -> Void) {
        // 이미 열려있으면 닫기
        window?.close()

        let viewModel = RouteListViewModel(apiKey: apiKey, arsId: arsId, onSelect: { [weak self] busNumber in
            onSelect(busNumber)
            self?.window?.close()
        })
        let routeView = RouteListContentView(viewModel: viewModel)

        let hostingView = NSHostingView(rootView: routeView)
        let windowSize = NSRect(x: 0, y: 0, width: 420, height: 500)
        hostingView.frame = windowSize

        let window = NSWindow(
            contentRect: windowSize,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "노선 목록"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.minSize = NSSize(width: 360, height: 300)

        // 설정창 옆에 배치
        if let settingsWindow = NSApp.windows.first(where: {
            $0.title.contains("Settings") || $0.title.contains("설정") ||
            $0.identifier?.rawValue.contains("settings") == true
        }) {
            let sf = settingsWindow.frame
            window.setFrameOrigin(NSPoint(x: sf.maxX + 12, y: sf.origin.y + sf.height - 500))
        } else {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}

// MARK: - 노선 리스트 ViewModel

@MainActor
private final class RouteListViewModel: ObservableObject {
    @Published var routes: [SeoulBusAPIService.RouteItem] = []
    @Published var stationName = ""
    @Published var isLoading = true
    @Published var errorMessage: String?

    let arsId: String
    let onSelect: (String) -> Void

    private let apiService = SeoulBusAPIService()
    private let apiKey: String

    init(apiKey: String, arsId: String, onSelect: @escaping (String) -> Void) {
        self.apiKey = apiKey
        self.arsId = arsId
        self.onSelect = onSelect
        Task { await fetchRoutes() }
    }

    func fetchRoutes() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await apiService.getStationRoutes(serviceKey: apiKey, arsId: arsId)
            stationName = result.stationName
            routes = result.routes
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func routeTypeLabel(_ type: String) -> String {
        switch type {
        case "1": return "공항"
        case "2": return "마을"
        case "3": return "간선"
        case "4": return "지선"
        case "5": return "순환"
        case "6": return "광역"
        case "7": return "인천"
        case "8": return "경기"
        case "9": return "폐지"
        default: return ""
        }
    }

    func routeTypeColor(_ type: String) -> Color {
        switch type {
        case "1": return .orange
        case "2": return .green
        case "3": return .blue
        case "4": return .green
        case "5": return .yellow
        case "6": return .red
        case "7": return .blue
        case "8": return .red
        default: return .gray
        }
    }
}

// MARK: - 노선 리스트 뷰

private struct RouteListContentView: View {
    @ObservedObject var viewModel: RouteListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.stationName.isEmpty ? "노선 조회 중..." : viewModel.stationName)
                        .font(.headline)
                    Text("정류소 \(viewModel.arsId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !viewModel.isLoading {
                    Text("\(viewModel.routes.count)개 노선")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // 콘텐츠
            if viewModel.isLoading {
                Spacer()
                ProgressView("노선 정보 조회 중...")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") {
                        Task { await viewModel.fetchRoutes() }
                    }
                }
                .padding()
                Spacer()
            } else {
                List(Array(viewModel.routes.enumerated()), id: \.offset) { _, route in
                    HStack(spacing: 10) {
                        // 노선 유형 배지
                        let typeLabel = viewModel.routeTypeLabel(route.routeType)
                        if !typeLabel.isEmpty {
                            Text(typeLabel)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(viewModel.routeTypeColor(route.routeType))
                                .cornerRadius(3)
                        }

                        // 노선 정보
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(route.busRouteAbrv)
                                    .font(.system(.body, weight: .semibold))
                                if route.busRouteAbrv != route.rtNm {
                                    Text("(\(route.rtNm))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            HStack(spacing: 8) {
                                Text(route.adirection)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(route.arrmsg1)
                                    .font(.caption)
                                    .foregroundStyle(route.arrmsg1.contains("분후") ? .blue : .secondary)
                            }
                        }

                        Spacer()

                        // 선택 버튼
                        Button("선택") {
                            viewModel.onSelect(route.busRouteAbrv)
                        }
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
