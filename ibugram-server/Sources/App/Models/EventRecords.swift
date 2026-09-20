import Fluent
import Foundation
import IBUgramKit

final class PlaceRecord: Model, @unchecked Sendable {
    static let schema = "places"

    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "latitude") var latitude: Double
    @Field(key: "longitude") var longitude: Double
    @Field(key: "is_campus_location") var isCampusLocation: Bool
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}

final class EventRecord: Model, @unchecked Sendable {
    static let schema = "events"

    @ID(key: .id) var id: UUID?
    @Field(key: "title") var title: String
    @OptionalField(key: "description") var description: String?
    @Field(key: "starts_at") var startsAt: Date
    @OptionalField(key: "ends_at") var endsAt: Date?
    @OptionalParent(key: "place_id") var place: PlaceRecord?
    @OptionalField(key: "capacity") var capacity: Int?
    @Parent(key: "host_id") var host: UserRecord
    @OptionalParent(key: "space_id") var space: SpaceRecord?
    @Field(key: "going_count") var goingCount: Int
    @Field(key: "interested_count") var interestedCount: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}

final class EventRSVPRecord: Model, @unchecked Sendable {
    static let schema = "event_rsvps"

    @ID(key: .id) var id: UUID?
    @Parent(key: "event_id") var event: EventRecord
    @Parent(key: "user_id") var user: UserRecord
    @Field(key: "status") var status: RSVPStatus
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}
