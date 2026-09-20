import Foundation
import IBUgramKit

enum EventEndpoints {
    struct List: Endpoint {
        typealias Response = Paginated<Event>

        var from: Date?
        var to: Date?
        var spaceID: UUID?
        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/events" }
        var queryItems: [URLQueryItem] {
            var items = PageRequest(limit: limit, cursor: cursor).queryItems
            if let from {
                items.append(URLQueryItem(name: "from", value: IBUgramDateCoding.string(from: from)))
            }
            if let to {
                items.append(URLQueryItem(name: "to", value: IBUgramDateCoding.string(from: to)))
            }
            if let spaceID {
                items.append(URLQueryItem(name: "space_id", value: spaceID.uuidString))
            }
            return items
        }
    }

    struct HappeningNow: Endpoint {
        typealias Response = Paginated<Event>

        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/events/happening-now" }
        var queryItems: [URLQueryItem] { PageRequest(limit: limit, cursor: cursor).queryItems }
    }

    struct Map: Endpoint {
        typealias Response = MapContents

        let bbox: BoundingBox

        var path: String { "/events/map" }
        var queryItems: [URLQueryItem] {
            [URLQueryItem(name: "bbox", value: bbox.queryValue)]
        }
    }

    struct Detail: Endpoint {
        typealias Response = Event

        let eventID: UUID

        var path: String { "/events/\(eventID.uuidString)" }
    }

    struct RSVP: Endpoint {
        typealias Response = EmptyResponse

        let eventID: UUID
        let status: RSVPStatus

        var method: HTTPMethod { .put }
        var path: String { "/events/\(eventID.uuidString)/rsvp" }
        var body: HTTPBody? { .json(SetRSVPBody(status: status)) }
    }

    struct Attendees: Endpoint {
        typealias Response = Paginated<EventAttendee>

        let eventID: UUID
        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/events/\(eventID.uuidString)/attendees" }
        var queryItems: [URLQueryItem] { PageRequest(limit: limit, cursor: cursor).queryItems }
    }
}
