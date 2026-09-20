import Fluent
import Foundation
import IBUgramKit
import Vapor

extension DemoSeed {
    func insertPlaces() async throws -> [String: PlaceRecord] {
        var places: [String: PlaceRecord] = [:]
        for spec in DemoSeedDataset.places {
            let place = PlaceRecord()
            place.id = SeedIdentity.uuid("place.\(spec.key)")
            place.name = spec.name
            place.latitude = spec.latitude
            place.longitude = spec.longitude
            place.isCampusLocation = true
            try await place.create(on: db)
            places[spec.key] = place
        }
        return places
    }

    func insertSpaces(_ users: [String: UserRecord]) async throws -> [String: SpaceRecord] {
        var spaces: [String: SpaceRecord] = [:]
        for spec in DemoSeedDataset.spaces {
            guard let creator = users[spec.createdBy] else { continue }
            let space = SpaceRecord()
            space.id = SeedIdentity.uuid("space.\(spec.key)")
            space.slug = spec.slug
            space.name = spec.name
            space.description = spec.description
            space.kind = spec.kind
            space.visibility = spec.visibility
            space.isOfficial = spec.isOfficial
            space.$createdBy.id = try creator.requireID()
            space.memberCount = 0
            try await space.create(on: db)
            for member in spec.members {
                guard let user = users[member.user] else { continue }
                let membership = SpaceMembershipRecord()
                membership.$space.id = try space.requireID()
                membership.$user.id = try user.requireID()
                membership.role = member.role
                try await membership.create(on: db)
            }
            spaces[spec.key] = space
        }
        return spaces
    }

    func insertEvents(
        users: [String: UserRecord],
        places: [String: PlaceRecord],
        spaces: [String: SpaceRecord]
    ) async throws -> [String: EventRecord] {
        var events: [String: EventRecord] = [:]
        let now = Date()
        for spec in DemoSeedDataset.events {
            guard let host = users[spec.host], let place = places[spec.place] else { continue }
            let event = EventRecord()
            event.id = SeedIdentity.uuid("event.\(spec.key)")
            event.title = spec.title
            event.description = spec.description
            event.startsAt = now.addingTimeInterval(spec.startOffset)
            event.endsAt = now.addingTimeInterval(spec.endOffset)
            event.$place.id = try place.requireID()
            event.$host.id = try host.requireID()
            if let spaceKey = spec.space {
                event.$space.id = try spaces[spaceKey]?.requireID()
            }
            event.capacity = spec.capacity
            event.goingCount = 0
            event.interestedCount = 0
            try await event.create(on: db)
            events[spec.key] = event
        }
        return events
    }
}
