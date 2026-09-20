import Foundation

public struct CreateEventBody: Codable, Sendable, Hashable {
    public var title: String
    public var description: String?
    public var startsAt: Date
    public var endsAt: Date?
    public var place: PlaceInput?
    public var capacity: Int?
    public var spaceId: UUID?

    public init(
        title: String,
        description: String? = nil,
        startsAt: Date,
        endsAt: Date? = nil,
        place: PlaceInput? = nil,
        capacity: Int? = nil,
        spaceId: UUID? = nil
    ) {
        self.title = title
        self.description = description
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.place = place
        self.capacity = capacity
        self.spaceId = spaceId
    }
}

public struct UpdateEventBody: Codable, Sendable, Hashable {
    public var title: String?
    public var description: String?
    public var startsAt: Date?
    public var endsAt: Date?
    public var place: PlaceInput?
    public var capacity: Int?

    public init(
        title: String? = nil,
        description: String? = nil,
        startsAt: Date? = nil,
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

public struct SetRSVPBody: Codable, Sendable, Hashable {
    public var status: RSVPStatus

    public init(status: RSVPStatus) {
        self.status = status
    }
}

/// `?bbox=minLongitude,minLatitude,maxLongitude,maxLatitude` for `GET /events/map`.
public struct BoundingBox: Sendable, Hashable, Codable {
    public var minimumLongitude: Double
    public var minimumLatitude: Double
    public var maximumLongitude: Double
    public var maximumLatitude: Double

    public init(
        minimumLongitude: Double,
        minimumLatitude: Double,
        maximumLongitude: Double,
        maximumLatitude: Double
    ) {
        self.minimumLongitude = minimumLongitude
        self.minimumLatitude = minimumLatitude
        self.maximumLongitude = maximumLongitude
        self.maximumLatitude = maximumLatitude
    }

    public init?(queryValue: String) {
        let parts = queryValue.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        self.init(
            minimumLongitude: parts[0],
            minimumLatitude: parts[1],
            maximumLongitude: parts[2],
            maximumLatitude: parts[3]
        )
    }

    public var queryValue: String {
        "\(minimumLongitude),\(minimumLatitude),\(maximumLongitude),\(maximumLatitude)"
    }
}
