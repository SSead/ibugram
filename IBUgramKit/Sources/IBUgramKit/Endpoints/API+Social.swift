import Foundation

extension API {
    public enum Spaces {
        public static let browse = Endpoint(.get, "/spaces")
        public static let create = Endpoint(.post, "/spaces")
        public static let detailTemplate = Endpoint(.get, "/spaces/:slug")
        public static let updateTemplate = Endpoint(.patch, "/spaces/:slug")
        public static let postsTemplate = Endpoint(.get, "/spaces/:slug/posts")
        public static let membersTemplate = Endpoint(.get, "/spaces/:slug/members")
        public static let joinTemplate = Endpoint(.post, "/spaces/:slug/membership")
        public static let leaveTemplate = Endpoint(.delete, "/spaces/:slug/membership")
        public static let setMemberRoleTemplate = Endpoint(.post, "/spaces/:slug/members/:userID/role")

        public static func detail(slug: String) -> Endpoint { detailTemplate.substituting(["slug": slug]) }
        public static func update(slug: String) -> Endpoint { updateTemplate.substituting(["slug": slug]) }
        public static func posts(slug: String) -> Endpoint { postsTemplate.substituting(["slug": slug]) }
        public static func members(slug: String) -> Endpoint { membersTemplate.substituting(["slug": slug]) }
        public static func join(slug: String) -> Endpoint { joinTemplate.substituting(["slug": slug]) }
        public static func leave(slug: String) -> Endpoint { leaveTemplate.substituting(["slug": slug]) }

        public static func setMemberRole(slug: String, userId: UUID) -> Endpoint {
            setMemberRoleTemplate.substituting(["slug": slug, "userID": userId.uuidString])
        }
    }

    public enum Events {
        public static let list = Endpoint(.get, "/events")
        public static let create = Endpoint(.post, "/events")
        public static let happeningNow = Endpoint(.get, "/events/happening-now")
        public static let map = Endpoint(.get, "/events/map")
        public static let detailTemplate = Endpoint(.get, "/events/:id")
        public static let updateTemplate = Endpoint(.patch, "/events/:id")
        public static let deleteTemplate = Endpoint(.delete, "/events/:id")
        public static let rsvpTemplate = Endpoint(.put, "/events/:id/rsvp")
        public static let attendeesTemplate = Endpoint(.get, "/events/:id/attendees")

        public static func detail(id: UUID) -> Endpoint { detailTemplate.substituting(["id": id.uuidString]) }
        public static func update(id: UUID) -> Endpoint { updateTemplate.substituting(["id": id.uuidString]) }
        public static func delete(id: UUID) -> Endpoint { deleteTemplate.substituting(["id": id.uuidString]) }
        public static func rsvp(id: UUID) -> Endpoint { rsvpTemplate.substituting(["id": id.uuidString]) }
        public static func attendees(id: UUID) -> Endpoint { attendeesTemplate.substituting(["id": id.uuidString]) }
    }

    public enum Search {
        public static let query = Endpoint(.get, "/search")
        public static let trending = Endpoint(.get, "/search/trending")
        public static let hashtagPostsTemplate = Endpoint(.get, "/hashtags/:tag/posts")

        public static func hashtagPosts(tag: String) -> Endpoint {
            hashtagPostsTemplate.substituting(["tag": tag])
        }
    }

    public enum Conversations {
        public static let list = Endpoint(.get, "/conversations")
        public static let create = Endpoint(.post, "/conversations")
        public static let messagesTemplate = Endpoint(.get, "/conversations/:id/messages")
        public static let sendMessageTemplate = Endpoint(.post, "/conversations/:id/messages")
        public static let readTemplate = Endpoint(.post, "/conversations/:id/read")
        public static let acceptTemplate = Endpoint(.post, "/conversations/:id/accept")

        public static func messages(id: UUID) -> Endpoint { messagesTemplate.substituting(["id": id.uuidString]) }
        public static func sendMessage(id: UUID) -> Endpoint { sendMessageTemplate.substituting(["id": id.uuidString]) }
        public static func markRead(id: UUID) -> Endpoint { readTemplate.substituting(["id": id.uuidString]) }
        public static func accept(id: UUID) -> Endpoint { acceptTemplate.substituting(["id": id.uuidString]) }
    }

    public enum Notifications {
        public static let list = Endpoint(.get, "/notifications")
        public static let unreadCount = Endpoint(.get, "/notifications/unread-count")
        public static let markRead = Endpoint(.post, "/notifications/read")
    }

    public enum Moderation {
        public static let report = Endpoint(.post, "/reports")
    }
}
