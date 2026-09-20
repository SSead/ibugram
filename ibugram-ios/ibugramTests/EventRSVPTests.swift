import Foundation
import Testing
@testable import ibugram
import IBUgramKit

private struct FailingCalendarStore: CalendarEventAdding {
    func add(_: Event) async throws {
        throw CalendarAddError.accessDenied
    }
}

@Suite("Event RSVP")
@MainActor
struct EventRSVPTests {
    @Test("going is applied immediately and kept when the request succeeds")
    func goingSucceedsOptimistically() async {
        let event = EventFixtures.filmNight
        let client = ScriptedAPIClient(stubs: EventFixtures.detailStubs(for: event))
        let viewModel = EventDetailViewModel(api: client, eventID: event.id, calendar: PreviewCalendarStore())
        await viewModel.load()
        #expect(viewModel.rsvp == .none)

        await viewModel.setRSVP(.going)

        #expect(viewModel.rsvp == .going)
        #expect(viewModel.event?.counts.going == event.counts.going + 1)
        let calls = await client.recordedCalls()
        #expect(calls.contains("PUT /events/\(event.id.uuidString)/rsvp"))
    }

    @Test("a failed going RSVP rolls the status and the going count back")
    func goingFailureRollsBack() async {
        let event = EventFixtures.filmNight
        let client = ScriptedAPIClient(
            stubs: EventFixtures.detailStubs(for: event),
            failures: ["PUT /events/\(event.id.uuidString)/rsvp": .offline]
        )
        let viewModel = EventDetailViewModel(api: client, eventID: event.id, calendar: PreviewCalendarStore())
        await viewModel.load()

        await viewModel.setRSVP(.going)

        #expect(viewModel.rsvp == .none)
        #expect(viewModel.event?.counts.going == event.counts.going)
        #expect(viewModel.presentedError != nil)
    }

    @Test("switching from interested to going moves the counts")
    func switchingRSVPAdjustsCounts() async {
        let event = EventFixtures.careerFair
        let client = ScriptedAPIClient(stubs: EventFixtures.detailStubs(for: event))
        let viewModel = EventDetailViewModel(api: client, eventID: event.id, calendar: PreviewCalendarStore())
        await viewModel.load()
        #expect(viewModel.rsvp == .interested)

        await viewModel.setRSVP(.going)

        #expect(viewModel.rsvp == .going)
        #expect(viewModel.event?.counts.going == event.counts.going + 1)
        #expect(viewModel.event?.counts.interested == event.counts.interested - 1)
    }

    @Test("tapping the selected RSVP again clears it")
    func selectingCurrentStatusClearsRSVP() async {
        let event = EventFixtures.openDay
        let client = ScriptedAPIClient(stubs: EventFixtures.detailStubs(for: event))
        let viewModel = EventDetailViewModel(api: client, eventID: event.id, calendar: PreviewCalendarStore())
        await viewModel.load()
        #expect(viewModel.rsvp == .going)

        await viewModel.setRSVP(.going)

        #expect(viewModel.rsvp == .none)
        #expect(viewModel.event?.counts.going == event.counts.going - 1)
    }

    @Test("going is refused locally when the event is at capacity")
    func fullEventBlocksGoing() async {
        let event = EventFixtures.fullLecture
        let client = ScriptedAPIClient(stubs: EventFixtures.detailStubs(for: event))
        let viewModel = EventDetailViewModel(api: client, eventID: event.id, calendar: PreviewCalendarStore())
        await viewModel.load()

        await viewModel.setRSVP(.going)

        #expect(viewModel.rsvp == .none)
        #expect(viewModel.event?.counts.going == event.counts.going)
        #expect(viewModel.presentedError != nil)
        let calls = await client.recordedCalls()
        #expect(calls.contains { $0.hasPrefix("PUT ") } == false)
    }

    @Test("a denied calendar permission is presented without crashing")
    func calendarPermissionFailureIsGraceful() async {
        let event = EventFixtures.openDay
        let client = ScriptedAPIClient(stubs: EventFixtures.detailStubs(for: event))
        let viewModel = EventDetailViewModel(
            api: client,
            eventID: event.id,
            calendar: FailingCalendarStore()
        )
        await viewModel.load()

        await viewModel.addToCalendar()

        #expect(viewModel.didAddToCalendar == false)
        #expect(viewModel.presentedError != nil)
    }
}
