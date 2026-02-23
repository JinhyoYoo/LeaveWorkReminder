import Foundation
import MapKit
import CoreLocation

enum WalkingTimeService {
    /// MapKit을 사용하여 사무실 주소에서 정류소(GPS 좌표)까지 도보 시간 계산
    static func calculateWalkingTime(from address: String,
                                      toLatitude: Double,
                                      toLongitude: Double) async -> Int? {
        // 주소 → 좌표 변환
        let geocoder = CLGeocoder()
        guard let placemarks = try? await geocoder.geocodeAddressString(address),
              let sourcePlacemark = placemarks.first,
              let sourceLocation = sourcePlacemark.location else {
            return nil
        }

        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: sourceLocation.coordinate))
        let destCoord = CLLocationCoordinate2D(latitude: toLatitude, longitude: toLongitude)
        let destMapItem = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))

        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destMapItem
        request.transportType = .walking

        let directions = MKDirections(request: request)
        guard let response = try? await directions.calculate(),
              let route = response.routes.first else {
            return nil
        }

        return Int(route.expectedTravelTime / 60)
    }
}
