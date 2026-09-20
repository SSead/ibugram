import CoreLocation
import Foundation
import IBUgramKit
import MapKit

enum MapBoundingBox {
    static let campusLatitude = 43.818
    static let campusLongitude = 18.310
    static let latitudeSpan = 0.02
    static let longitudeSpan = 0.03

    static var campusCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: campusLatitude, longitude: campusLongitude)
    }

    static var campusRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: campusCenter,
            span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan)
        )
    }

    static func from(region: MKCoordinateRegion) -> BoundingBox? {
        let halfLat = region.span.latitudeDelta / 2
        let halfLon = region.span.longitudeDelta / 2
        return validated(
            minLongitude: region.center.longitude - halfLon,
            minLatitude: region.center.latitude - halfLat,
            maxLongitude: region.center.longitude + halfLon,
            maxLatitude: region.center.latitude + halfLat
        )
    }

    static func fromQuery(_ value: String) -> BoundingBox? {
        guard let parsed = BoundingBox(queryValue: value) else { return nil }
        return validated(parsed)
    }

    static func validated(_ box: BoundingBox) -> BoundingBox? {
        validated(
            minLongitude: box.minimumLongitude,
            minLatitude: box.minimumLatitude,
            maxLongitude: box.maximumLongitude,
            maxLatitude: box.maximumLatitude
        )
    }

    static func validated(
        minLongitude: Double,
        minLatitude: Double,
        maxLongitude: Double,
        maxLatitude: Double
    ) -> BoundingBox? {
        let west = clamped(minLongitude, lower: -180, upper: 180)
        let east = clamped(maxLongitude, lower: -180, upper: 180)
        let south = clamped(minLatitude, lower: -90, upper: 90)
        let north = clamped(maxLatitude, lower: -90, upper: 90)
        let minLon = min(west, east)
        let maxLon = max(west, east)
        let minLat = min(south, north)
        let maxLat = max(south, north)
        guard minLon < maxLon, minLat < maxLat else { return nil }
        return BoundingBox(
            minimumLongitude: minLon,
            minimumLatitude: minLat,
            maximumLongitude: maxLon,
            maximumLatitude: maxLat
        )
    }

    private static func clamped(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}
