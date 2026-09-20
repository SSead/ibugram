import Foundation

enum ActivityCopy {
    static func sentence(for item: ActivityNotification) -> String {
        switch item.kind {
        case .like:
            return "\(actorPhrase(for: item)) liked your post"
        case .comment:
            if let body = item.comment?.body, item.groupCount <= 1 {
                return "\(primaryActor(for: item)) commented: \(body)"
            }
            return "\(actorPhrase(for: item)) commented on your post"
        case .reply:
            return "\(primaryActor(for: item)) replied to your comment"
        case .follow:
            return "\(actorPhrase(for: item)) started following you"
        case .mention:
            return "\(actorPhrase(for: item)) mentioned you in a post"
        case .spaceInvite:
            let space = item.space?.name ?? "a Space"
            return "\(primaryActor(for: item)) invited you to \(space)"
        case .eventReminder:
            let title = item.event?.title ?? "an event"
            return "Reminder: \(title)"
        }
    }

    static func primaryActor(for item: ActivityNotification) -> String {
        item.actors.first?.displayName ?? "Someone"
    }

    static func actorPhrase(for item: ActivityNotification) -> String {
        let name = primaryActor(for: item)
        let others = max(item.groupCount - 1, 0)
        guard others > 0 else { return name }
        let noun = others == 1 ? "other" : "others"
        return "\(name) and \(others) \(noun)"
    }
}

enum RelativeTimestamp {
    static func abbreviated(from date: Date, now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func accessible(from date: Date, now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
