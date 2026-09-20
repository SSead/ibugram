import Foundation
import IBUgramKit

protocol CalendarEventAdding: Sendable {
    func add(_ event: Event) async throws
}

enum CalendarAddError: Error, Sendable {
    case accessDenied
    case saveFailed
}

@MainActor
@Observable
final class EventDetailViewModel: ErrorPresenting {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    private(set) var phase: Phase = .loading
    private(set) var event: Event?
    private(set) var isMutatingRSVP = false
    private(set) var didAddToCalendar = false
    private(set) var isAddingToCalendar = false
    var presentedError: PresentedError?

    private let api: any APIRequesting
    private let eventID: UUID
    private let calendar: any CalendarEventAdding

    init(
        api: any APIRequesting,
        eventID: UUID,
        calendar: any CalendarEventAdding = EventKitCalendarStore()
    ) {
        self.api = api
        self.eventID = eventID
        self.calendar = calendar
    }

    var rsvp: RSVPStatus { event?.rsvp ?? .none }

    var isGoingDisabled: Bool {
        guard let event else { return false }
        return !event.canRSVPGoing
    }

    func load() async {
        phase = .loading
        do {
            event = try await api.send(EventEndpoints.Detail(eventID: eventID))
            phase = .loaded
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func reload() async {
        do {
            event = try await api.send(EventEndpoints.Detail(eventID: eventID))
            phase = .loaded
        } catch {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func setRSVP(_ status: RSVPStatus) async {
        guard !isMutatingRSVP, let current = event else { return }
        let nextStatus = current.rsvp == status ? RSVPStatus.none : status
        if nextStatus == .going && !current.canRSVPGoing {
            present(APIError.conflict)
            return
        }
        let next = current.applyingRSVP(nextStatus)
        event = next
        isMutatingRSVP = true
        defer { isMutatingRSVP = false }
        do {
            _ = try await api.send(EventEndpoints.RSVP(eventID: eventID, status: nextStatus))
        } catch {
            event = current
            present(error) { [weak self] in await self?.setRSVP(status) }
        }
    }

    func addToCalendar() async {
        guard let event, !isAddingToCalendar else { return }
        isAddingToCalendar = true
        defer { isAddingToCalendar = false }
        do {
            try await calendar.add(event)
            didAddToCalendar = true
        } catch CalendarAddError.accessDenied {
            presentedError = PresentedError(
                title: "Calendar permission needed",
                message: "IBUgram could not add this event. Allow calendar access in Settings and try again."
            )
        } catch {
            presentedError = PresentedError(
                title: "Could not add to calendar",
                message: "The event was not saved. You can try again, or add it from the Calendar app."
            )
        }
    }
}
