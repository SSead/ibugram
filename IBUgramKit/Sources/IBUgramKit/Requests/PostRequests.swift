import Foundation

public struct PlaceInput: Codable, Sendable, Hashable {
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

/// Either attaches an existing event by `id`, or describes a new one to create alongside
/// the post. `id` wins when both are supplied.
public struct PostEventInput: Codable, Sendable, Hashable {
    public var id: UUID?
    public var title: String?
    public var description: String?
    public var startsAt: Date?
    public var endsAt: Date?
    public var place: PlaceInput?
    public var capacity: Int?

    public init(id: UUID) {
        self.id = id
    }

    public init(
        title: String,
        description: String? = nil,
        startsAt: Date,
        endsAt: Date? = nil,
        place: PlaceInput? = nil,
        capacity: Int? = nil
    ) {
        self.title = title
        self.description = description
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.place = place
        self.capacity = capacity
    }
}

public struct CreatePostBody: Codable, Sendable, Hashable {
    public var mediaIds: [UUID]
    public var caption: String?
    public var spaceId: UUID?
    public var event: PostEventInput?
    public var place: PlaceInput?
    public var commentsEnabled: Bool

    public init(
        mediaIds: [UUID],
        caption: String? = nil,
        spaceId: UUID? = nil,
        event: PostEventInput? = nil,
        place: PlaceInput? = nil,
        commentsEnabled: Bool = true
    ) {
        self.mediaIds = mediaIds
        self.caption = caption
        self.spaceId = spaceId
        self.event = event
        self.place = place
        self.commentsEnabled = commentsEnabled
    }
}

public struct UpdatePostBody: Codable, Sendable, Hashable {
    public var caption: String?
    public var commentsEnabled: Bool?

    public init(caption: String? = nil, commentsEnabled: Bool? = nil) {
        self.caption = caption
        self.commentsEnabled = commentsEnabled
    }
}

public struct CreateCommentBody: Codable, Sendable, Hashable {
    public var body: String
    public var parentId: UUID?

    public init(body: String, parentId: UUID? = nil) {
        self.body = body
        self.parentId = parentId
    }
}
