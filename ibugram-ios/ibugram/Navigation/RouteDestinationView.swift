import SwiftUI

/// Every pushed screen in the app resolves here. Feature teams replace their own cases with
/// the real view and touch nothing else.
struct RouteDestinationView: View {
    let route: Route

    var body: some View {
        switch route {
        case .profile(let username):
            unbuilt("Profile of @\(username)", owner: "Profiles & Social Graph")
        case .followers(let username):
            unbuilt("Followers of @\(username)", owner: "Profiles & Social Graph")
        case .following(let username):
            unbuilt("@\(username) is following", owner: "Profiles & Social Graph")
        case .post(let id):
            unbuilt("Post \(id.uuidString.prefix(8))", owner: "Feed & Posts")
        case .postComments(let postID):
            unbuilt("Comments on \(postID.uuidString.prefix(8))", owner: "Feed & Posts")
        case .postLikes(let postID):
            unbuilt("Likes on \(postID.uuidString.prefix(8))", owner: "Feed & Posts")
        case .hashtag(let tag):
            unbuilt("#\(tag)", owner: "Search & Discovery")
        case .space(let slug):
            unbuilt("Space /\(slug)", owner: "Spaces")
        case .spaceMembers(let slug):
            unbuilt("Members of /\(slug)", owner: "Spaces")
        case .event(let id):
            unbuilt("Event \(id.uuidString.prefix(8))", owner: "Campus Events")
        case .eventAttendees(let eventID):
            unbuilt("Attendees of \(eventID.uuidString.prefix(8))", owner: "Campus Events")
        case .campusMap:
            unbuilt("Campus map", owner: "Campus Events")
        case .conversation(let id):
            unbuilt("Conversation \(id.uuidString.prefix(8))", owner: "Messaging")
        case .messageRequests:
            unbuilt("Message requests", owner: "Messaging")
        case .savedPosts:
            unbuilt("Saved posts", owner: "Profiles & Social Graph")
        case .settings:
            SettingsPlaceholderView()
        case .activeSessions:
            unbuilt("Active sessions", owner: "Identity & Access")
        }
    }

    private func unbuilt(_ title: String, owner: String) -> some View {
        UnbuiltDestinationView(title: title, owner: owner)
    }
}

#Preview("Route destination") {
    NavigationStack {
        RouteDestinationView(route: .profile(username: "amina.h"))
    }
}

#Preview("Route destination · dark") {
    NavigationStack {
        RouteDestinationView(route: .space(slug: "ibu-robotics"))
    }
    .preferredColorScheme(.dark)
}
