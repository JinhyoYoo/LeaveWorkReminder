import SwiftUI

final class AppSettings: ObservableObject {
    @AppStorage("arsId") var arsId: String = Constants.defaultArsId
    @AppStorage("busNumbers") var busNumbersRaw: String = Constants.defaultBusNumber
    @AppStorage("officeAddress") var officeAddress: String = Constants.defaultAddress
    @AppStorage("checkHour") var checkHour: Int = Constants.defaultCheckHour
    @AppStorage("checkMinute") var checkMinute: Int = Constants.defaultCheckMinute
    @AppStorage("walkingTimeMode") var walkingTimeMode: WalkingTimeMode = .auto
    @AppStorage("manualWalkingMinutes") var manualWalkingMinutes: Int = Constants.defaultManualWalkingMinutes
    @AppStorage("elevatorMinutes") var elevatorMinutes: Int = Constants.defaultElevatorMinutes
    @AppStorage("bufferMinutes") var bufferMinutes: Int = Constants.defaultBufferMinutes
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("skipWeekends") var skipWeekends: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    // 캐시된 정류소 정보
    @AppStorage("cachedStId") var cachedStId: String = ""
    @AppStorage("cachedGpsX") var cachedGpsX: Double = 0
    @AppStorage("cachedGpsY") var cachedGpsY: Double = 0
    // 노선별 캐시: JSON {"1311": {"busRouteId": "xxx", "ord": "36"}, ...}
    @AppStorage("cachedRouteMap") var cachedRouteMapRaw: String = ""

    // MARK: - Bus Numbers

    var busNumbers: [String] {
        busNumbersRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    func addBusNumber(_ bus: String) {
        let trimmed = bus.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var list = busNumbers
        if !list.contains(trimmed) {
            list.append(trimmed)
            busNumbersRaw = list.joined(separator: ",")
            clearCache()
        }
    }

    func removeBusNumber(_ bus: String) {
        var list = busNumbers
        list.removeAll { $0 == bus }
        busNumbersRaw = list.joined(separator: ",")
        clearCache()
    }

    // MARK: - Route Cache

    struct CachedRoute: Codable {
        let busRouteId: String
        let ord: String
    }

    var routeMap: [String: CachedRoute] {
        get {
            guard let data = cachedRouteMapRaw.data(using: .utf8),
                  let map = try? JSONDecoder().decode([String: CachedRoute].self, from: data) else { return [:] }
            return map
        }
        set {
            if let data = try? JSONEncoder().encode(newValue), let str = String(data: data, encoding: .utf8) {
                cachedRouteMapRaw = str
            }
        }
    }

    func setCachedRoute(busNumber: String, busRouteId: String, ord: String) {
        var map = routeMap
        map[busNumber] = CachedRoute(busRouteId: busRouteId, ord: ord)
        routeMap = map
    }

    func cachedRoute(for busNumber: String) -> CachedRoute? {
        routeMap[busNumber]
    }

    // MARK: - Status

    var isConfigured: Bool {
        !apiKey.isEmpty && !arsId.isEmpty && !busNumbers.isEmpty
    }

    var hasCachedRouteInfo: Bool {
        guard !cachedStId.isEmpty else { return false }
        let map = routeMap
        return busNumbers.allSatisfy { map[$0] != nil }
    }

    func clearCache() {
        cachedStId = ""
        cachedGpsX = 0
        cachedGpsY = 0
        cachedRouteMapRaw = ""
    }
}

enum WalkingTimeMode: String, CaseIterable {
    case auto = "auto"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .auto: return "자동 (MapKit)"
        case .manual: return "수동 입력"
        }
    }
}
