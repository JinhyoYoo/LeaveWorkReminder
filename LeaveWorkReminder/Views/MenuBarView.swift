import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 타이틀
            HStack {
                Text("퇴근 알리미")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                ForEach(viewModel.settings.busNumbers, id: \.self) { bus in
                    Text("\(bus)번")
                        .font(.system(size: 12))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // 버스 도착 현황
            StatusView(
                arrivalInfos: viewModel.currentArrivalInfos,
                monitorState: viewModel.monitorState,
                totalLeadTime: viewModel.totalLeadTimeMinutes,
                lastUpdated: viewModel.lastUpdated
            )

            Divider()

            // 액션 버튼들
            HStack(spacing: 8) {
                Button("지금 확인") {
                    Task { await viewModel.checkNow() }
                }
                .disabled(!viewModel.settings.isConfigured)

                if viewModel.isPolling {
                    Button("모니터링 중단") {
                        viewModel.stopMonitoring()
                    }
                } else {
                    Button("모니터링 시작") {
                        viewModel.startMonitoring()
                    }
                    .disabled(!viewModel.settings.isConfigured)
                }

                Button("테스트 알림") {
                    viewModel.sendTestNotification()
                }

                Spacer()

                Button {
                    openSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.activate(ignoringOtherApps: true)
                        for window in NSApp.windows where window.title.contains("Settings") || window.title.contains("설정") || window.identifier?.rawValue.contains("settings") == true {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                }
            }

            // 설정 미완료 경고
            if !viewModel.settings.isConfigured {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("설정에서 API 키를 입력해주세요")
                        .font(.system(size: 12))
                }
            }

            // 알림 스타일 안내
            if viewModel.showAlertStyleWarning {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.slash")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12))
                    Text("알림이 바로 사라집니다.")
                        .font(.system(size: 11))
                    Button("알림 설정 열기") {
                        viewModel.openNotificationSettings()
                    }
                    .font(.system(size: 11))
                }
                .padding(6)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // 오늘의 확인 기록
            if !viewModel.todayLogs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("오늘의 기록")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.todayLogs.suffix(5), id: \.timestamp) { log in
                        HStack {
                            Text(log.timestamp, style: .time)
                                .font(.system(size: 11))
                            Text(log.message)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()
            }

            Button("종료") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
