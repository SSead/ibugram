import Foundation
import IBUgramKit

extension Event {
    func applyingRSVP(_ status: RSVPStatus) -> Event {
        var copy = self
        let previous = viewer?.rsvp ?? .none
        var going = counts.going
        var interested = counts.interested
        switch previous {
        case .going: going -= 1
        case .interested: interested -= 1
        case .none: break
        }
        switch status {
        case .going: going += 1
        case .interested: interested += 1
        case .none: break
        }
        copy.counts = EventCounts(going: max(0, going), interested: max(0, interested))
        copy.viewer = EventViewerState(rsvp: status)
        return copy
    }

    var rsvp: RSVPStatus { viewer?.rsvp ?? .none }

    var canRSVPGoing: Bool {
        rsvp == .going || !isFull
    }
}

extension RSVPStatus {
    var title: String {
        switch self {
        case .going: "Going"
        case .interested: "Interested"
        case .none: "Not going"
        }
    }
}

enum EventScheduleText {
    static func range(startsAt: Date, endsAt: Date?) -> String {
        let start = startsAt.formatted(date: .abbreviated, time: .shortened)
        guard let endsAt else { return start }
        if Calendar.current.isDate(startsAt, inSameDayAs: endsAt) {
            return "\(startsAt.formatted(date: .abbreviated, time: .shortened)) – \(endsAt.formatted(date: .omitted, time: .shortened))"
        }
        return "\(start) – \(endsAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
