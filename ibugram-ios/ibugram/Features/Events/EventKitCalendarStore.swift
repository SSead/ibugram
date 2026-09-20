import EventKit
import Foundation
import IBUgramKit

struct EventKitCalendarStore: CalendarEventAdding {
    func add(_ event: Event) async throws {
        let store = EKEventStore()
        let allowed = await Self.requestAccess(using: store)
        guard allowed else { throw CalendarAddError.accessDenied }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarAddError.saveFailed
        }
        let item = EKEvent(eventStore: store)
        item.title = event.title
        item.notes = event.description
        item.startDate = event.startsAt
        item.endDate = event.endsAt ?? event.startsAt.addingTimeInterval(3_600)
        item.calendar = calendar
        item.location = event.place?.name
        do {
            try store.save(item, span: .thisEvent)
        } catch {
            throw CalendarAddError.saveFailed
        }
    }

    private static func requestAccess(using store: EKEventStore) async -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        @unknown default:
            return false
        }
    }
}

struct PreviewCalendarStore: CalendarEventAdding {
    func add(_: Event) async throws {}
}
