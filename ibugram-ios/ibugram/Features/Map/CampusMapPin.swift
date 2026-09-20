import CoreLocation
import Foundation
import IBUgramKit
import MapKit

enum MapPinID: Hashable {
    case event(UUID)
    case post(UUID)
}

struct CampusMapPin: Identifiable {
    let id: MapPinID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let systemImage: String

    var route: Route {
        switch id {
        case .event(let eventID): .event(id: eventID)
        case .post(let postID): .post(id: postID)
        }
    }

    var accessibilityLabel: String {
        switch id {
        case .event: "Event, \(title)"
        case .post: "Post, \(title)"
        }
    }

    static func pins(from contents: MapContents) -> [CampusMapPin] {
        let events = contents.events.compactMap { event -> CampusMapPin? in
            guard let place = event.place else { return nil }
            return CampusMapPin(
                id: .event(event.id),
                title: event.title,
                coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                systemImage: "calendar"
            )
        }
        let posts = contents.posts.compactMap { post -> CampusMapPin? in
            guard let place = post.location else { return nil }
            return CampusMapPin(
                id: .post(post.id),
                title: post.caption ?? place.name,
                coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                systemImage: "photo"
            )
        }
        return events + posts
    }
}
