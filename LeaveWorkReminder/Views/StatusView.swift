import SwiftUI

struct StatusView: View {
    let arrivalInfos: [BusArrivalInfo]
    let monitorState: MonitorState
    let totalLeadTime: Int
    let lastUpdated: Date?

    /// 가장 빨리 도착하는 버스
    private var earliest: BusArrivalInfo? {
        arrivalInfos
            .filter { $0.exps1 != nil && !$0.isServiceEnded }
            .min { ($0.exps1 ?? Int.max) < ($1.exps1 ?? Int.max) }
    }

    /// 탈 수 있는 다음 버스 도착 시간(분) - 리드타임 이상인 가장 빠른 도착
    private var nextCatchableBusMinutes: Int? {
        var candidates: [Int] = []
        for info in arrivalInfos where !info.isServiceEnded {
            if let m1 = info.firstArrivalMinutes, m1 >= totalLeadTime {
                candidates.append(m1)
            }
            if let m2 = info.secondArrivalMinutes, m2 >= totalLeadTime {
                candidates.append(m2)
            }
        }
        return candidates.min()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 상태 헤더
            HStack {
                Circle()
                    .fill(monitorState.color)
                    .frame(width: 9, height: 9)
                Text(monitorState.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastUpdated {
                    Text(lastUpdated, style: .time)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            if arrivalInfos.isEmpty {
                Text("버스 도착 정보 없음")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(arrivalInfos.enumerated()), id: \.offset) { _, info in
                    let isEarliest = earliest?.busNumber == info.busNumber

                    VStack(alignment: .leading, spacing: 5) {
                        // 버스 번호 헤더
                        HStack(spacing: 5) {
                            Image(systemName: "bus.fill")
                                .foregroundStyle(isEarliest ? .orange : .blue)
                                .font(.system(size: 13))
                            Text("\(info.busNumber)번")
                                .font(.system(size: 15, weight: isEarliest ? .bold : .medium))
                            if isEarliest && arrivalInfos.count > 1 {
                                Text("가장 빠름")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }

                        // 도착 정보
                        HStack(spacing: 14) {
                            arrivalBadge(label: "첫번째", message: info.arrmsg1, isLast: info.isLast1)
                            arrivalBadge(label: "다음", message: info.arrmsg2, isLast: info.isLast2)
                        }
                    }
                    .padding(.vertical, 3)
                }

                Divider()

                // 리드타임 비교 (가장 빠른 버스 기준)
                if let earliest = earliest, let minutes = earliest.firstArrivalMinutes {
                    if minutes < totalLeadTime {
                        // 이번 버스는 탈 수 없음
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                            if let nextMinutes = nextCatchableBusMinutes {
                                let leaveIn = nextMinutes - totalLeadTime
                                Text("이번 버스는 못타요. \(leaveIn)분 뒤에 퇴근하세요")
                                    .font(.system(size: 12))
                            } else {
                                Text("이번 버스는 못타요")
                                    .font(.system(size: 12))
                            }
                        }
                    } else if minutes == totalLeadTime {
                        // 지금 출발해야 함
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.orange)
                            Text("지금 출발하세요! \(earliest.busNumber)번 \(minutes)분 후")
                                .font(.system(size: 12))
                        }
                    } else {
                        // 여유 있음
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                            Text("아직 여유 있음 (리드타임: \(totalLeadTime)분)")
                                .font(.system(size: 12))
                        }
                    }
                }
            }
        }
    }

    private func arrivalBadge(label: String, message: String, isLast: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(size: 13))
            if isLast {
                Text("막차")
                    .font(.system(size: 9))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.red.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
}

enum MonitorState {
    case idle
    case waitingForCheckTime
    case polling
    case waitingForNextBus
    case notified
    case error(String)
    case serviceEnded

    var displayName: String {
        switch self {
        case .idle: return "대기"
        case .waitingForCheckTime: return "체크 시간 대기 중"
        case .polling: return "모니터링 중"
        case .waitingForNextBus: return "다음 버스 대기 중"
        case .notified: return "알림 완료"
        case .error(let msg): return "오류: \(msg)"
        case .serviceEnded: return "운행 종료"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .waitingForCheckTime: return .yellow
        case .polling: return .green
        case .waitingForNextBus: return .orange
        case .notified: return .blue
        case .error: return .red
        case .serviceEnded: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .idle: return "bus"
        case .waitingForCheckTime: return "clock"
        case .polling: return "bus.fill"
        case .waitingForNextBus: return "arrow.forward.circle"
        case .notified: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle"
        case .serviceEnded: return "moon.fill"
        }
    }
}
