import Foundation
import IBUgramKit
import Vapor

enum BoundingBoxParser {
    static let maximumSpanDegrees = 2.0

    static func parse(_ raw: String?) throws -> BoundingBox {
        guard let raw, let box = BoundingBox(queryValue: raw) else {
            throw APIError.validationFailed(
                "bbox must be minLongitude,minLatitude,maxLongitude,maxLatitude.",
                details: ["bbox": .string("malformed")]
            )
        }
        guard (-180...180).contains(box.minimumLongitude),
              (-180...180).contains(box.maximumLongitude),
              (-90...90).contains(box.minimumLatitude),
              (-90...90).contains(box.maximumLatitude)
        else {
            throw APIError.validationFailed(
                "bbox coordinates are out of range.",
                details: ["bbox": .string("out_of_range")]
            )
        }
        guard box.minimumLongitude < box.maximumLongitude,
              box.minimumLatitude < box.maximumLatitude
        else {
            throw APIError.validationFailed(
                "bbox min must be less than max.",
                details: ["bbox": .string("inverted")]
            )
        }
        let longitudeSpan = box.maximumLongitude - box.minimumLongitude
        let latitudeSpan = box.maximumLatitude - box.minimumLatitude
        guard longitudeSpan <= maximumSpanDegrees, latitudeSpan <= maximumSpanDegrees else {
            throw APIError.validationFailed(
                "bbox is too large.",
                details: ["bbox": .string("too_large")]
            )
        }
        return box
    }
}

extension PlaceRecord {
    func asDTO() throws -> Place {
        Place(
            id: try requireID(),
            name: name,
            latitude: latitude,
            longitude: longitude,
            isCampusLocation: isCampusLocation
        )
    }
}

extension EventRecord {
    func asDTO(
        viewerRSVP: RSVPStatus,
        urls: MediaURLBuilder,
        postId: UUID?
    ) throws -> Event {
        Event(
            id: try requireID(),
            title: title,
            description: description,
            startsAt: startsAt,
            endsAt: endsAt,
            place: try place.map { try $0.asDTO() },
            capacity: capacity,
            host: try host.asDTO(urls: urls),
            space: try space.map { try $0.asSummary(urls: urls) },
            counts: EventCounts(going: goingCount, interested: interestedCount),
            viewer: EventViewerState(rsvp: viewerRSVP),
            postId: postId
        )
    }
}

extension EventRSVPRecord {
    func asAttendee(urls: MediaURLBuilder) throws -> EventAttendee {
        EventAttendee(
            id: try requireID(),
            user: try user.asDTO(urls: urls),
            status: status,
            respondedAt: updatedAt ?? createdAt ?? Date()
        )
    }
}

extension EventAttendee: @retroactive AsyncRequestDecodable {}
extension EventAttendee: @retroactive AsyncResponseEncodable {}
extension EventAttendee: @retroactive Content {}

extension Event: @retroactive AsyncRequestDecodable {}
extension Event: @retroactive AsyncResponseEncodable {}
extension Event: @retroactive Content {}

extension Place: @retroactive AsyncRequestDecodable {}
extension Place: @retroactive AsyncResponseEncodable {}
extension Place: @retroactive Content {}

extension MapContents: @retroactive AsyncRequestDecodable {}
extension MapContents: @retroactive AsyncResponseEncodable {}
extension MapContents: @retroactive Content {}

extension CreateEventBody: @retroactive AsyncRequestDecodable {}
extension CreateEventBody: @retroactive AsyncResponseEncodable {}
extension CreateEventBody: @retroactive Content {}

extension UpdateEventBody: @retroactive AsyncRequestDecodable {}
extension UpdateEventBody: @retroactive AsyncResponseEncodable {}
extension UpdateEventBody: @retroactive Content {}

extension SetRSVPBody: @retroactive AsyncRequestDecodable {}
extension SetRSVPBody: @retroactive AsyncResponseEncodable {}
extension SetRSVPBody: @retroactive Content {}
