import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Events", .serialized)
struct EventTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"
    private let faculty = "e.kovac@ibu.edu.ba"
    private let other = "second.student@stu.ibu.edu.ba"

    @Test("A host can create, read, update and delete an event")
    func eventLifecycle() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: faculty)
            let starts = Date().addingTimeInterval(86_400)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Open Day",
                        description: "Campus tour",
                        startsAt: starts,
                        endsAt: starts.addingTimeInterval(7_200),
                        place: PlaceInput(
                            name: "Main Building",
                            latitude: 43.8184,
                            longitude: 18.3097,
                            isCampusLocation: true
                        ),
                        capacity: 50
                    ))
                }
            )
            #expect(created.status == .created)
            let event = try created.content.decode(Event.self)
            #expect(event.title == "Open Day")
            #expect(event.capacity == 50)
            #expect(event.viewer?.rsvp == RSVPStatus.none)
            #expect(event.place?.name == "Main Building")

            let detail = try await context.app.testing().sendRequest(
                .GET,
                API.Events.detail(id: event.id).fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(detail.status == .ok)

            let patched = try await context.app.testing().sendRequest(
                .PATCH,
                API.Events.update(id: event.id).fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: { try $0.content.encode(UpdateEventBody(title: "Open Day 2026")) }
            )
            #expect(try patched.content.decode(Event.self).title == "Open Day 2026")

            let deleted = try await context.app.testing().sendRequest(
                .DELETE,
                API.Events.delete(id: event.id).fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(deleted.status == .noContent)
        }
    }

    @Test("Unauthenticated event requests are rejected")
    func eventsRequireAuth() async throws {
        try await withCommunityTestServer { context in
            let id = UUID()
            let list = try await context.app.testing().sendRequest(.GET, API.Events.list.fullPath)
            #expect(list.status == .unauthorized)
            let create = try await context.app.testing().sendRequest(.POST, API.Events.create.fullPath)
            #expect(create.status == .unauthorized)
            let happening = try await context.app.testing().sendRequest(.GET, API.Events.happeningNow.fullPath)
            #expect(happening.status == .unauthorized)
            let map = try await context.app.testing().sendRequest(.GET, API.Events.map.fullPath)
            #expect(map.status == .unauthorized)
            let detail = try await context.app.testing().sendRequest(.GET, API.Events.detail(id: id).fullPath)
            #expect(detail.status == .unauthorized)
            let update = try await context.app.testing().sendRequest(.PATCH, API.Events.update(id: id).fullPath)
            #expect(update.status == .unauthorized)
            let delete = try await context.app.testing().sendRequest(.DELETE, API.Events.delete(id: id).fullPath)
            #expect(delete.status == .unauthorized)
            let rsvp = try await context.app.testing().sendRequest(.PUT, API.Events.rsvp(id: id).fullPath)
            #expect(rsvp.status == .unauthorized)
            let attendees = try await context.app.testing().sendRequest(.GET, API.Events.attendees(id: id).fullPath)
            #expect(attendees.status == .unauthorized)
        }
    }

    @Test("A non-host cannot patch or delete an event")
    func nonHostCannotMutate() async throws {
        try await withCommunityTestServer { context in
            let host = try await context.signIn(as: faculty)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(host.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Lecture",
                        startsAt: Date().addingTimeInterval(3_600)
                    ))
                }
            )
            let event = try created.content.decode(Event.self)
            let otherUser = try await context.signIn(as: student)
            let patch = try await context.app.testing().sendRequest(
                .PATCH,
                API.Events.update(id: event.id).fullPath,
                headers: context.authorized(otherUser.accessToken),
                beforeRequest: { try $0.content.encode(UpdateEventBody(title: "Hijacked")) }
            )
            #expect(patch.status == .forbidden)
            let delete = try await context.app.testing().sendRequest(
                .DELETE,
                API.Events.delete(id: event.id).fullPath,
                headers: context.authorized(otherUser.accessToken)
            )
            #expect(delete.status == .forbidden)
        }
    }

    @Test("RSVP capacity rejects the overflow seat")
    func capacityRejectsOverflow() async throws {
        try await withCommunityTestServer { context in
            let host = try await context.signIn(as: faculty)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(host.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Tiny Workshop",
                        startsAt: Date().addingTimeInterval(3_600),
                        capacity: 1
                    ))
                }
            )
            let event = try created.content.decode(Event.self)
            let first = try await context.signIn(as: student)
            let going = try await context.app.testing().sendRequest(
                .PUT,
                API.Events.rsvp(id: event.id).fullPath,
                headers: context.authorized(first.accessToken),
                beforeRequest: { try $0.content.encode(SetRSVPBody(status: .going)) }
            )
            #expect(going.status == .ok)
            let goingEvent = try going.content.decode(Event.self)
            #expect(goingEvent.viewer?.rsvp == .going)
            #expect(goingEvent.counts.going == 1)

            let second = try await context.signIn(as: other)
            let overflow = try await context.app.testing().sendRequest(
                .PUT,
                API.Events.rsvp(id: event.id).fullPath,
                headers: context.authorized(second.accessToken),
                beforeRequest: { try $0.content.encode(SetRSVPBody(status: .going)) }
            )
            #expect(overflow.status == .conflict)
            #expect(overflow.apiError?.code == .conflict)
        }
    }

    @Test("Changing an RSVP updates the existing row rather than inserting another")
    func rsvpChangeIsAnUpdate() async throws {
        try await withCommunityTestServer { context in
            let host = try await context.signIn(as: faculty)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(host.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Meetup",
                        startsAt: Date().addingTimeInterval(3_600),
                        capacity: 10
                    ))
                }
            )
            let event = try created.content.decode(Event.self)
            let user = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .PUT,
                API.Events.rsvp(id: event.id).fullPath,
                headers: context.authorized(user.accessToken),
                beforeRequest: { try $0.content.encode(SetRSVPBody(status: .going)) }
            )
            let changed = try await context.app.testing().sendRequest(
                .PUT,
                API.Events.rsvp(id: event.id).fullPath,
                headers: context.authorized(user.accessToken),
                beforeRequest: { try $0.content.encode(SetRSVPBody(status: .interested)) }
            )
            let updated = try changed.content.decode(Event.self)
            #expect(updated.viewer?.rsvp == .interested)
            #expect(updated.counts.going == 0)
            #expect(updated.counts.interested == 1)

            let rows = try await EventRSVPRecord.query(on: context.app.db)
                .filter(\.$event.$id == event.id)
                .all()
            #expect(rows.count == 1)
            #expect(rows[0].status == .interested)
        }
    }

    @Test("Malformed and oversized bounding boxes are rejected")
    func bboxValidationRejectsBadInput() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: student)
            let malformed = try await context.app.testing().sendRequest(
                .GET,
                API.Events.map.fullPath + "?bbox=not-a-box",
                headers: context.authorized(session.accessToken)
            )
            #expect(malformed.status == .unprocessableEntity)
            #expect(malformed.apiError?.code == .validationFailed)

            let inverted = try await context.app.testing().sendRequest(
                .GET,
                API.Events.map.fullPath + "?bbox=18.4,43.9,18.3,43.8",
                headers: context.authorized(session.accessToken)
            )
            #expect(inverted.status == .unprocessableEntity)

            let huge = try await context.app.testing().sendRequest(
                .GET,
                API.Events.map.fullPath + "?bbox=-180,-90,180,90",
                headers: context.authorized(session.accessToken)
            )
            #expect(huge.status == .unprocessableEntity)
            #expect(huge.apiError?.details["bbox"]?.stringValue == "too_large")
        }
    }

    @Test("Happening-now returns an in-progress event and the map returns geo-tagged content")
    func happeningNowAndMap() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: faculty)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Live Talk",
                        startsAt: Date().addingTimeInterval(-1_800),
                        endsAt: Date().addingTimeInterval(1_800),
                        place: PlaceInput(
                            name: "A Amphitheatre",
                            latitude: 43.8184,
                            longitude: 18.3097,
                            isCampusLocation: true
                        )
                    ))
                }
            )
            let event = try created.content.decode(Event.self)

            let happening = try await context.app.testing().sendRequest(
                .GET,
                API.Events.happeningNow.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(happening.status == .ok)
            let live = try happening.content.decode(Paginated<Event>.self)
            #expect(live.items.contains { $0.id == event.id })

            let map = try await context.app.testing().sendRequest(
                .GET,
                API.Events.map.fullPath + "?bbox=18.30,43.81,18.32,43.83",
                headers: context.authorized(session.accessToken)
            )
            #expect(map.status == .ok)
            let contents = try map.content.decode(MapContents.self)
            #expect(contents.events.contains { $0.id == event.id })
        }
    }

    @Test("Attendees lists going RSVPs")
    func attendeesList() async throws {
        try await withCommunityTestServer { context in
            let host = try await context.signIn(as: faculty)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Events.create.fullPath,
                headers: context.authorized(host.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateEventBody(
                        title: "Fair",
                        startsAt: Date().addingTimeInterval(3_600),
                        capacity: 20
                    ))
                }
            )
            let event = try created.content.decode(Event.self)
            _ = try await context.app.testing().sendRequest(
                .PUT,
                API.Events.rsvp(id: event.id).fullPath,
                headers: context.authorized(host.accessToken),
                beforeRequest: { try $0.content.encode(SetRSVPBody(status: .going)) }
            )
            let attendees = try await context.app.testing().sendRequest(
                .GET,
                API.Events.attendees(id: event.id).fullPath,
                headers: context.authorized(host.accessToken)
            )
            #expect(attendees.status == .ok)
            #expect(try attendees.content.decode(Paginated<EventAttendee>.self).items.count == 1)
        }
    }
}
