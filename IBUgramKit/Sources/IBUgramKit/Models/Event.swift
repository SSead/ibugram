import Foundation

public struct Place: Codable, Sendable, Hashable, Identifiable {
    /// Free-form places typed by the composer have no row of their own until saved.
    public var id: UUID?
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var isCampusLocation: Bool

    public init(
        id: UUID? = nil,
        name: String,
        latitude: Double,
        longitude: Double,
        isCampusLocation: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isCampusLocation = isCampusLocation
    }
}

public enum RSVPStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case going
    case interested
    case none
}

public struct EventCounts: Codable, Sendable, Hashable {
    public var going: Int
    public var interested: Int

    public init(going: Int = 0, interested: Int = 0) {
        self.going = going
        self.interested = interested
    }
}

public struct EventViewerState: Codable, Sendable, Hashable {
    public var rsvp: RSVPStatus

    public init(rsvp: RSVPStatus = .none) {
        self.rsvp = rsvp
    }
}

public struct Event: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var description: String?
    public var startsAt: Date
    public var endsAt: Date?
    public var place: Place?
    public var capacity: Int?
    public var host: User
    public var space: SpaceSummary?
    public var counts: EventCounts
    public var viewer: EventViewerState?
    public var postId: UUID?

    public init(
        id: UUID,
        title: String,
        description: String? = nil,
        startsAt: Date,
        endsAt: Date? = nil,
        place: Place? = nil,
        capacity: Int? = nil,
        host: User,
        space: SpaceSummary? = nil,
        counts: EventCounts = EventCounts(),
        viewer: EventViewerState? = nil,
        postId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.place = place
        self.capacity = capacity
        self.host = host
        self.space = space
        self.counts = counts
        self.viewer = viewer
        self.postId = postId
    }

    public var isFull: Bool {
        guard let capacity else { return false }
        return counts.going >= capacity
    }
}

public struct EventAttendee: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var user: User
    public var status: RSVPStatus
    public var respondedAt: Date

    public init(id: UUID, user: User, status: RSVPStatus, respondedAt: Date) {
        self.id = id
        self.user = user
        self.status = status
        self.respondedAt = respondedAt
    }
}

/// `GET /events/map` returns both pinned events and geo-tagged posts for one bounding box.
public struct MapContents: Codable, Sendable, Hashable {
    public var events: [Event]
    public var posts: [Post]

    public init(events: [Event] = [], posts: [Post] = []) {
        self.events = events
        self.posts = posts
    }
}
