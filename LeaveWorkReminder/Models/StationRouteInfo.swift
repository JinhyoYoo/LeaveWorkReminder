import Foundation

struct StationRouteInfo: Sendable {
    let stId: String          // 정류소 고유 ID
    let arsId: String         // 정류소 번호
    let stationName: String   // 정류소 이름
    let busRouteId: String    // 노선 ID
    let busNumber: String     // 버스 번호
    let ord: String           // 정류소 순번
    let gpsX: Double          // 경도
    let gpsY: Double          // 위도
}
