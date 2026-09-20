import Foundation
import IBUgramKit

@MainActor
@Observable
final class EventsListViewModel: ErrorPresenting {
    let events: PagedList<Event>
    var presentedError: PresentedError?

    init(api: any APIRequesting) {
        events = PagedList { cursor in
            try await api.send(EventEndpoints.List(from: Date(), cursor: cursor))
        }
    }

    func load() async {
        await events.loadFirstPageIfNeeded()
    }

    func reload() async {
        await events.reload()
        if case .failed(let error) = events.phase, !events.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }
}
