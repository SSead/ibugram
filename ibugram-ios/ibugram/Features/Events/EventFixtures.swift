import Foundation
import IBUgramKit

enum EventFixtures {
    static let careerFair = FeedFixtures.careerFair
    static let openDay = FeedFixtures.openDay
    static let filmNight = FeedFixtures.filmNight

    static let fullLecture = Event(
        id: UUID(uuidString: "77777777-7777-4777-8777-777777777774") ?? UUID(),
        title: "Guest lecture",
        description: "Capacity is already reached.",
        startsAt: Date(timeIntervalSinceNow: 2 * 3_600),
        endsAt: Date(timeIntervalSinceNow: 4 * 3_600),
        place: FeedFixtures.cafeteria,
        capacity: 40,
        host: SampleData.professorKovac,
        space: FeedFixtures.robotics,
        counts: EventCounts(going: 40, interested: 12),
        viewer: EventViewerState(rsvp: .none),
        postId: FeedFixtures.facultyAuthor.id
    )

    static let upcoming: [Event] = [openDay, careerFair, filmNight, fullLecture]
    static let happeningNow: [Event] = FeedFixtures.happeningNow

    static let attendees: [EventAttendee] = [
        EventAttendee(
            id: UUID(uuidString: "c1111111-1111-4111-8111-111111111111") ?? UUID(),
            user: SampleData.amina,
            status: .going,
            respondedAt: Date(timeIntervalSinceNow: -3_600)
        ),
        EventAttendee(
            id: UUID(uuidString: "c1111111-1111-4111-8111-111111111112") ?? UUID(),
            user: ProfileFixtures.followedStudent,
            status: .going,
            respondedAt: Date(timeIntervalSinceNow: -2_400)
        ),
        EventAttendee(
            id: UUID(uuidString: "c1111111-1111-4111-8111-111111111113") ?? UUID(),
            user: SampleData.professorKovac,
            status: .interested,
            respondedAt: Date(timeIntervalSinceNow: -1_200)
        )
    ]

    static var listStubs: [String: any Sendable] {
        var stubs: [String: any Sendable] = [
            "GET /events": Paginated(items: upcoming),
            "GET /events/happening-now": Paginated(items: happeningNow)
        ]
        for event in upcoming {
            stubs.merge(detailStubs(for: event)) { _, new in new }
        }
        return stubs
    }

    static var emptyListStubs: [String: any Sendable] {
        [
            "GET /events": Paginated<Event>(items: []),
            "GET /events/happening-now": Paginated<Event>(items: [])
        ]
    }

    static func detailStubs(for event: Event) -> [String: any Sendable] {
        [
            "GET /events/\(event.id.uuidString)": event,
            "GET /events/\(event.id.uuidString)/attendees": Paginated(items: attendees)
        ]
    }
}
