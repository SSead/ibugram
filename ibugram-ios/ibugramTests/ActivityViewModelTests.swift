import Foundation
import Testing
@testable import ibugram

@Suite("Notification grouping")
struct ActivityGroupingTests {
    @Test("notifications split into today, this week and earlier")
    func groupsByRelativeDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let now = Date(timeIntervalSince1970: 1_779_638_400)

        let groups = ActivityGrouping.groups(from: ActivityFixtures.all, now: now, calendar: calendar)

        #expect(groups.map(\.period) == [.today, .thisWeek, .earlier])
        #expect(groups[0].items.map(\.id) == [
            ActivityFixtures.replyToday.id,
            ActivityFixtures.likeToday.id,
            ActivityFixtures.commentToday.id
        ])
        #expect(groups[1].items.map(\.id) == [
            ActivityFixtures.followThisWeek.id,
            ActivityFixtures.mentionThisWeek.id
        ])
        #expect(groups[2].items.map(\.id) == [
            ActivityFixtures.spaceInviteEarlier.id,
            ActivityFixtures.eventReminderEarlier.id
        ])
    }

    @Test("grouped copy names the first actor and the remaining count")
    func groupedCopy() {
        #expect(
            ActivityCopy.sentence(for: ActivityFixtures.likeToday)
                == "Leila Marković and 4 others liked your post"
        )
        #expect(
            ActivityCopy.sentence(for: ActivityFixtures.commentToday)
                == "Prof. Dr. Damir Kovač commented: Excellent turnout."
        )
        #expect(
            ActivityCopy.sentence(for: ActivityFixtures.followThisWeek)
                == "Leila Marković started following you"
        )
    }
}

@Suite("Unread activity count")
struct ActivityViewModelUnreadTests {
    @Test("the badge uses the unread-count endpoint and drops after items are marked read")
    func unreadCountThenMarkRead() async {
        let client = ScriptedAPIClient(stubs: [
            "GET /notifications": Page(items: ActivityFixtures.all),
            "GET /notifications/unread-count": UnreadCountResponse(count: 3)
        ])
        let badge = ActivityBadgeStore()
        let viewModel = ActivityViewModel(
            api: client,
            badge: badge,
            now: { ActivityFixtures.now },
            calendar: Calendar(identifier: .gregorian)
        )

        await viewModel.load()

        let calls = await client.recordedCalls()
        #expect(calls.contains("GET /notifications/unread-count"))
        #expect(calls.contains("POST /notifications/read"))
        #expect(badge.unreadCount == 0)
        #expect(viewModel.isRead(ActivityFixtures.likeToday))
    }

    @Test("a live notification_created frame increments the badge")
    func websocketSeamIncrementsBadge() {
        let badge = ActivityBadgeStore()
        badge.setUnreadCount(2)
        badge.applyNotificationCreated(ActivityFixtures.likeToday)
        #expect(badge.unreadCount == 3)
        badge.applyUnreadCountChanged(notifications: 1)
        #expect(badge.unreadCount == 1)
    }

    @Test("an already-read live frame does not bump the badge")
    func readLiveFrameIsIgnored() {
        let badge = ActivityBadgeStore()
        badge.setUnreadCount(4)
        badge.applyNotificationCreated(ActivityFixtures.followThisWeek)
        #expect(badge.unreadCount == 4)
    }
}
