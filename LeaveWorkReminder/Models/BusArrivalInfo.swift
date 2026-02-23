import Foundation

struct BusArrivalInfo: Sendable {
    let busRouteId: String
    let busNumber: String
    let stationName: String
    let arrmsg1: String       // 첫번째 버스 도착 메시지
    let arrmsg2: String       // 두번째 버스 도착 메시지
    let exps1: Int?           // 첫번째 버스 도착 예상 초
    let exps2: Int?           // 두번째 버스 도착 예상 초
    let isLast1: Bool         // 첫번째 버스 막차 여부
    let isLast2: Bool         // 두번째 버스 막차 여부

    var firstArrivalMinutes: Int? {
        guard let exps1 = exps1 else { return nil }
        return exps1 / 60
    }

    var secondArrivalMinutes: Int? {
        guard let exps2 = exps2 else { return nil }
        return exps2 / 60
    }

    var isServiceEnded: Bool {
        arrmsg1.contains("운행종료") || arrmsg1.contains("출발대기")
    }

    static let empty = BusArrivalInfo(
        busRouteId: "", busNumber: "", stationName: "",
        arrmsg1: "정보 없음", arrmsg2: "정보 없음",
        exps1: nil, exps2: nil,
        isLast1: false, isLast2: false
    )
}
