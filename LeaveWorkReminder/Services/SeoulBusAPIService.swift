import Foundation
import os

private let logger = Logger(subsystem: "com.yoo.LeaveWorkReminder", category: "API")

actor SeoulBusAPIService {

    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case noData
        case parseError
        case busNotFound(String)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "잘못된 URL"
            case .networkError(let error): return "네트워크 오류: \(error.localizedDescription)"
            case .noData: return "응답 데이터 없음"
            case .parseError: return "XML 파싱 오류"
            case .busNotFound(let bus): return "\(bus)번 버스를 찾을 수 없음"
            case .apiError(let msg): return "API 오류: \(msg)"
            }
        }
    }

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - 헤더 에러 체크

    private func checkHeaderError(data: Data) throws {
        let headerParser = XMLParsingService(itemElementName: "msgHeader")
        let headers = headerParser.parse(data: data)
        if let header = headers.first {
            let headerCd = header["headerCd"] ?? ""
            let headerMsg = header["headerMsg"] ?? ""
            if headerCd != "0" && !headerCd.isEmpty {
                throw APIError.apiError("[\(headerCd)] \(headerMsg)")
            }
        }
    }

    // MARK: - 정류소 정보 조회 (단일 버스)

    func getStationInfo(serviceKey: String, arsId: String, busNumber: String) async throws -> StationRouteInfo {
        let urlString = Constants.Endpoint.stationByUid(serviceKey: serviceKey, arsId: arsId)
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)
        try checkHeaderError(data: data)
        let parser = XMLParsingService()
        let items = parser.parse(data: data)

        guard !items.isEmpty else { throw APIError.noData }

        guard let matchedItem = items.first(where: { item in
            let rtNm = item["rtNm"] ?? ""
            let abrv = item["busRouteAbrv"] ?? ""
            return rtNm == busNumber || abrv == busNumber
        }) else {
            throw APIError.busNotFound(busNumber)
        }

        guard let stId = matchedItem["stId"],
              let busRouteId = matchedItem["busRouteId"],
              let ord = matchedItem["staOrd"] else {
            throw APIError.parseError
        }

        return StationRouteInfo(
            stId: stId,
            arsId: arsId,
            stationName: matchedItem["stNm"] ?? "",
            busRouteId: busRouteId,
            busNumber: busNumber,
            ord: ord,
            gpsX: Double(matchedItem["gpsX"] ?? "0") ?? 0,
            gpsY: Double(matchedItem["gpsY"] ?? "0") ?? 0
        )
    }

    // MARK: - 정류소 정보 조회 (복수 버스)

    func getStationInfos(serviceKey: String, arsId: String, busNumbers: [String]) async throws -> [StationRouteInfo] {
        let urlString = Constants.Endpoint.stationByUid(serviceKey: serviceKey, arsId: arsId)
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)
        try checkHeaderError(data: data)
        let parser = XMLParsingService()
        let items = parser.parse(data: data)

        guard !items.isEmpty else { throw APIError.noData }

        var results: [StationRouteInfo] = []
        for busNumber in busNumbers {
            guard let matchedItem = items.first(where: { item in
                let rtNm = item["rtNm"] ?? ""
                let abrv = item["busRouteAbrv"] ?? ""
                return rtNm == busNumber || abrv == busNumber
            }) else { continue }

            guard let stId = matchedItem["stId"],
                  let busRouteId = matchedItem["busRouteId"],
                  let ord = matchedItem["staOrd"] else { continue }

            results.append(StationRouteInfo(
                stId: stId,
                arsId: arsId,
                stationName: matchedItem["stNm"] ?? "",
                busRouteId: busRouteId,
                busNumber: busNumber,
                ord: ord,
                gpsX: Double(matchedItem["gpsX"] ?? "0") ?? 0,
                gpsY: Double(matchedItem["gpsY"] ?? "0") ?? 0
            ))
        }

        guard !results.isEmpty else {
            throw APIError.busNotFound(busNumbers.joined(separator: ", "))
        }

        return results
    }

    // MARK: - 정류소 전체 노선 조회

    struct RouteItem {
        let busRouteAbrv: String   // 약칭 (1311)
        let rtNm: String           // 정식명 (1311오산)
        let adirection: String     // 방향
        let arrmsg1: String        // 첫번째 버스 도착 메시지
        let routeType: String      // 노선 유형
    }

    func getStationRoutes(serviceKey: String, arsId: String) async throws -> (stationName: String, routes: [RouteItem]) {
        let urlString = Constants.Endpoint.stationByUid(serviceKey: serviceKey, arsId: arsId)
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)
        try checkHeaderError(data: data)
        let parser = XMLParsingService()
        let items = parser.parse(data: data)

        guard !items.isEmpty else { throw APIError.noData }

        let stationName = items.first?["stNm"] ?? ""
        let routes = items.map { item in
            RouteItem(
                busRouteAbrv: item["busRouteAbrv"] ?? "",
                rtNm: item["rtNm"] ?? "",
                adirection: item["adirection"] ?? "",
                arrmsg1: item["arrmsg1"] ?? "",
                routeType: item["routeType"] ?? ""
            )
        }
        return (stationName, routes)
    }

    // MARK: - 도착 정보 조회

    func getArrivalInfo(serviceKey: String, stId: String, busRouteId: String, ord: String, busNumber: String) async throws -> BusArrivalInfo {
        let urlString = Constants.Endpoint.arrInfoByRoute(
            serviceKey: serviceKey, stId: stId, busRouteId: busRouteId, ord: ord
        )
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)
        try checkHeaderError(data: data)
        let parser = XMLParsingService()
        let items = parser.parse(data: data)

        guard let item = items.first else { throw APIError.noData }

        return BusArrivalInfo(
            busRouteId: busRouteId,
            busNumber: busNumber,
            stationName: item["stNm"] ?? "",
            arrmsg1: item["arrmsg1"] ?? "정보 없음",
            arrmsg2: item["arrmsg2"] ?? "정보 없음",
            exps1: Int(item["exps1"] ?? ""),
            exps2: Int(item["exps2"] ?? ""),
            isLast1: item["isLast1"] == "1",
            isLast2: item["isLast2"] == "1"
        )
    }

    // MARK: - API 연결 테스트

    func testConnection(serviceKey: String, arsId: String) async throws -> String {
        let urlString = Constants.Endpoint.stationByUid(serviceKey: serviceKey, arsId: arsId)
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        let rawBody = String(data: data, encoding: .utf8) ?? ""
        logger.notice("[API Test] URL: \(urlString)")
        logger.notice("[API Test] Response (\(data.count) bytes): \(rawBody.prefix(500))")
        // 파일 로그
        let logMsg = "[API Test]\nURL: \(urlString)\nResponse: \(rawBody)\n"
        try? logMsg.write(toFile: NSHomeDirectory() + "/LeaveWorkReminder/api_debug.log", atomically: true, encoding: .utf8)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        // 헤더 에러 체크 (인증 실패 등)
        let headerParser = XMLParsingService(itemElementName: "msgHeader")
        let headers = headerParser.parse(data: data)
        if let header = headers.first {
            let headerCd = header["headerCd"] ?? ""
            let headerMsg = header["headerMsg"] ?? ""
            if headerCd != "0" && !headerCd.isEmpty {
                throw APIError.apiError("[\(headerCd)] \(headerMsg)")
            }
        }

        let parser = XMLParsingService()
        let items = parser.parse(data: data)

        if httpResponse.statusCode == 200 && !items.isEmpty {
            let stationName = items.first?["stNm"] ?? "알 수 없음"
            let routeCount = items.count
            return "연결 성공! 정류소: \(stationName), 노선 \(routeCount)개"
        } else {
            throw APIError.apiError("HTTP \(httpResponse.statusCode): \(rawBody.prefix(300))")
        }
    }
}
