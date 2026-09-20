import Foundation
import IBUgramKit

@MainActor
@Observable
final class EventAttendeesViewModel: ErrorPresenting {
    let attendees: PagedList<EventAttendee>
    var presentedError: PresentedError?

    init(api: any APIRequesting, eventID: UUID) {
        attendees = PagedList { cursor in
            try await api.send(EventEndpoints.Attendees(eventID: eventID, cursor: cursor))
        }
    }

    func load() async {
        await attendees.loadFirstPageIfNeeded()
    }

    func reload() async {
        await attendees.reload()
        if case .failed(let error) = attendees.phase, !attendees.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }
}
