import Foundation

enum ActivityPeriod: String, Sendable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case earlier = "Earlier"

    var id: String { rawValue }
}

struct ActivityGroup: Identifiable, Sendable, Equatable {
    let period: ActivityPeriod
    let items: [ActivityNotification]

    var id: ActivityPeriod { period }
}

@MainActor
@Observable
final class ActivityBadgeStore {
    private(set) var unreadCount = 0

    func setUnreadCount(_ count: Int) {
        unreadCount = max(count, 0)
    }

    /// Call when a `notification_created` WebSocket frame arrives. Activity does not subscribe
    /// to the socket; the realtime owner should decode the payload and forward it here.
    func applyNotificationCreated(_ notification: ActivityNotification) {
        if !notification.isRead {
            unreadCount += 1
        }
    }

    /// Call when an `unread_count_changed` frame arrives, using `payload.notifications`.
    func applyUnreadCountChanged(notifications: Int) {
        unreadCount = max(notifications, 0)
    }

    func applyMarkedRead(count: Int) {
        unreadCount = max(unreadCount - count, 0)
    }
}

enum ActivityGrouping {
    static func groups(
        from items: [ActivityNotification],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ActivityGroup] {
        var today: [ActivityNotification] = []
        var thisWeek: [ActivityNotification] = []
        var earlier: [ActivityNotification] = []

        let startOfToday = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday

        for item in items {
            if item.createdAt >= startOfToday {
                today.append(item)
            } else if item.createdAt >= weekStart {
                thisWeek.append(item)
            } else {
                earlier.append(item)
            }
        }

        return [
            ActivityGroup(period: .today, items: today),
            ActivityGroup(period: .thisWeek, items: thisWeek),
            ActivityGroup(period: .earlier, items: earlier)
        ].filter { !$0.items.isEmpty }
    }
}

@MainActor
@Observable
final class ActivityViewModel: ErrorPresenting {
    let feed: Paginated<ActivityNotification>
    let badge: ActivityBadgeStore
    var presentedError: PresentedError?
    private(set) var locallyReadIDs: Set<UUID> = []
    private(set) var followOverrides: [UUID: Bool] = [:]
    private var markedIDs: Set<UUID> = []

    private let api: any APIRequesting
    private let now: () -> Date
    private let calendar: Calendar

    init(
        api: any APIRequesting,
        badge: ActivityBadgeStore = ActivityBadgeStore(),
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.api = api
        self.badge = badge
        self.now = now
        self.calendar = calendar
        feed = Paginated { cursor in
            try await api.send(NotificationEndpoints.List(cursor: cursor))
        }
    }

    var groups: [ActivityGroup] {
        ActivityGrouping.groups(from: feed.items, now: now(), calendar: calendar)
    }

    func load() async {
        async let unread: Void = refreshUnreadCount()
        async let list: Void = feed.loadFirstPageIfNeeded()
        _ = await (unread, list)
        await markVisibleUnread()
    }

    func reload() async {
        async let unread: Void = refreshUnreadCount()
        async let list: Void = feed.reload()
        _ = await (unread, list)
        locallyReadIDs.removeAll()
        markedIDs.removeAll()
        await markVisibleUnread()
    }

    func refreshUnreadCount() async {
        do {
            let response = try await api.send(NotificationEndpoints.UnreadCount())
            badge.setUnreadCount(response.count)
        } catch {
            return
        }
    }

    func ingestNotificationCreated(_ notification: ActivityNotification) {
        badge.applyNotificationCreated(notification)
    }

    func ingestUnreadCountChanged(notifications: Int) {
        badge.applyUnreadCountChanged(notifications: notifications)
    }

    func displayed(_ user: User) -> User {
        guard let isFollowing = followOverrides[user.id] else { return user }
        return user.withFollowState(isFollowing: isFollowing)
    }

    func toggleFollow(_ user: User) async {
        let previous = followOverrides[user.id] ?? user.viewer?.isFollowing ?? false
        followOverrides[user.id] = !previous
        do {
            if previous {
                _ = try await api.send(UserEndpoints.Unfollow(userID: user.id))
            } else {
                _ = try await api.send(UserEndpoints.Follow(userID: user.id))
            }
        } catch {
            followOverrides[user.id] = previous
            present(error) { [weak self] in await self?.toggleFollow(user) }
        }
    }

    func isRead(_ item: ActivityNotification) -> Bool {
        item.isRead || locallyReadIDs.contains(item.id)
    }

    func markVisibleUnread() async {
        let unread = feed.items.filter { !isRead($0) && !markedIDs.contains($0.id) }
        guard !unread.isEmpty else { return }
        let ids = unread.map(\.id)
        markedIDs.formUnion(ids)
        do {
            _ = try await api.send(NotificationEndpoints.MarkRead(ids: ids))
            locallyReadIDs.formUnion(ids)
            badge.applyMarkedRead(count: ids.count)
        } catch {
            markedIDs.subtract(ids)
        }
    }
}
