import Foundation

enum Constants {
    static let baseURL = "http://ws.bus.go.kr/api/rest"

    /// serviceKey를 URL-safe하게 인코딩
    /// data.go.kr에서 Encoding/Decoding 키 어느 쪽을 넣어도 동작하도록 처리
    static func encodeServiceKey(_ key: String) -> String {
        // 이미 %인코딩된 키면 먼저 디코딩
        let decoded = key.removingPercentEncoding ?? key
        // +, /, = 등 base64 문자를 퍼센트 인코딩
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+/=&")
        return decoded.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
    }

    enum Endpoint {
        static func stationByUid(serviceKey: String, arsId: String) -> String {
            let key = encodeServiceKey(serviceKey)
            return "\(baseURL)/stationinfo/getStationByUid?ServiceKey=\(key)&arsId=\(arsId)"
        }

        static func busRouteList(serviceKey: String, busNumber: String) -> String {
            let key = encodeServiceKey(serviceKey)
            return "\(baseURL)/busRouteInfo/getBusRouteList?ServiceKey=\(key)&strSrch=\(busNumber)"
        }

        static func arrInfoByRoute(serviceKey: String, stId: String, busRouteId: String, ord: String) -> String {
            let key = encodeServiceKey(serviceKey)
            return "\(baseURL)/arrive/getArrInfoByRoute?ServiceKey=\(key)&stId=\(stId)&busRouteId=\(busRouteId)&ord=\(ord)"
        }
    }

    static let defaultArsId = "22600"
    static let defaultBusNumber = "1311"
    static let defaultAddress = "서울특별시 강남구 테헤란로2길 27"
    static let defaultCheckHour = 16
    static let defaultCheckMinute = 50
    static let defaultManualWalkingMinutes = 10
    static let defaultElevatorMinutes = 5
    static let defaultBufferMinutes = 5
    static let pollingIntervalSeconds: TimeInterval = 60
}
