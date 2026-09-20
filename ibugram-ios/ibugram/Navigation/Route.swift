import Foundation

/// The single typed navigation vocabulary for the whole app. Adding a screen means adding a
/// case here and a branch in `RouteDestinationView` — never a bespoke `NavigationLink(destination:)`.
enum Route: Hashable, Sendable {
    case profile(username: String)
    case followers(username: String)
    case following(username: String)
    case post(id: UUID)
    case postComments(postID: UUID)
    case postLikes(postID: UUID)
    case hashtag(tag: String)
    case space(slug: String)
    case spaceMembers(slug: String)
    case event(id: UUID)
    case eventAttendees(eventID: UUID)
    case campusMap
    case conversation(id: UUID)
    case messageRequests
    case savedPosts
    case settings
    case activeSessions
}
