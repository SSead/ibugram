import IBUgramKit
import Vapor

/// The whole contract is registered so the route table is complete and a client gets a
/// structured `501` instead of a bare `404` while a feature team is still building.
/// Deleting a line here is the first step of implementing that endpoint.
struct ReservedEndpointController: RouteCollection {
    static let reserved: [Endpoint] = [
        API.Users.profileTemplate,
        API.Users.profilePostsTemplate,
        API.Users.followersTemplate,
        API.Users.followingTemplate,
        API.Users.followTemplate,
        API.Users.unfollowTemplate,
        API.Users.blockTemplate,
        API.Users.unblockTemplate,
        API.Users.suggested,
        API.Users.savedPosts,
        API.Feed.following,
        API.Feed.discover,
        API.Posts.create,
        API.Posts.detailTemplate,
        API.Posts.updateTemplate,
        API.Posts.deleteTemplate,
        API.Posts.likeTemplate,
        API.Posts.unlikeTemplate,
        API.Posts.saveTemplate,
        API.Posts.unsaveTemplate,
        API.Posts.likesTemplate,
        API.Posts.commentsTemplate,
        API.Posts.createCommentTemplate,
        API.Comments.deleteTemplate,
        API.Comments.likeTemplate,
        API.Comments.unlikeTemplate,
        API.Spaces.browse,
        API.Spaces.create,
        API.Spaces.detailTemplate,
        API.Spaces.updateTemplate,
        API.Spaces.postsTemplate,
        API.Spaces.membersTemplate,
        API.Spaces.joinTemplate,
        API.Spaces.leaveTemplate,
        API.Spaces.setMemberRoleTemplate,
        API.Events.list,
        API.Events.create,
        API.Events.happeningNow,
        API.Events.map,
        API.Events.detailTemplate,
        API.Events.updateTemplate,
        API.Events.deleteTemplate,
        API.Events.rsvpTemplate,
        API.Events.attendeesTemplate,
        API.Search.query,
        API.Search.trending,
        API.Search.hashtagPostsTemplate,
        API.Conversations.list,
        API.Conversations.create,
        API.Conversations.messagesTemplate,
        API.Conversations.sendMessageTemplate,
        API.Conversations.readTemplate,
        API.Conversations.acceptTemplate,
        API.Notifications.list,
        API.Notifications.unreadCount,
        API.Notifications.markRead,
        API.Moderation.report
    ]

    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        for endpoint in Self.reserved {
            authenticated.on(endpoint, use: Self.placeholder(for: endpoint))
        }
        /// The upgrade carries its access token in the query string, not a bearer header,
        /// so it must not sit behind the header authenticator.
        routes.on(API.webSocket, use: Self.placeholder(for: API.webSocket))
    }

    private static func placeholder(for endpoint: Endpoint) -> @Sendable (Request) throws -> Response {
        let label = "\(endpoint.method.rawValue) \(endpoint.fullPath)"
        return { _ in try Response.json(APIError.notImplemented(label), status: .notImplemented) }
    }
}
