import SwiftUI

struct RouteDestinationView: View {
    let route: Route

    @Environment(AuthSessionStore.self) private var session

    var body: some View {
        switch route {
        case .profile(let username):
            ProfileView(username: username)
        case .followers(let username):
            FollowListView(username: username, kind: .followers)
        case .following(let username):
            FollowListView(username: username, kind: .following)
        case .post(let id):
            PostDetailView(postID: id)
        case .postComments(let postID):
            PostDetailView(postID: postID)
        case .postLikes(let postID):
            PostLikesView(postID: postID)
        case .hashtag(let tag):
            HashtagDetailView(tag: tag)
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
            if let username = session.currentUser?.username {
                ProfileView(username: username, initialTab: .saved)
            } else {
                unbuilt("Saved posts", owner: "Profiles & Social Graph")
            }
        case .settings:
            SettingsView()
        case .editProfile:
            EditProfileRouteView()
        case .changeUsername:
            ChangeUsernameRouteView()
        case .blockedAccounts:
            BlockedAccountsView()
        case .activeSessions:
            ActiveSessionsView()
        }
    }

    private func unbuilt(_ title: String, owner: String) -> some View {
        UnbuiltDestinationView(title: title, owner: owner)
    }
}

private struct EditProfileRouteView: View {
    @Environment(AuthSessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let user = session.currentUser {
            EditProfileView(user: user) { updated in
                session.update(user: updated)
                dismiss()
            }
        } else {
            UnbuiltDestinationView(title: "Edit profile", owner: "Profiles & Social Graph")
        }
    }
}

private struct ChangeUsernameRouteView: View {
    @Environment(AuthSessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let user = session.currentUser {
            ChangeUsernameView(currentUsername: user.username) { updated in
                session.update(user: updated)
                dismiss()
            }
        } else {
            UnbuiltDestinationView(title: "Username", owner: "Identity & Access")
        }
    }
}

#Preview("Route destination") {
    NavigationStack {
        RouteDestinationView(route: .profile(username: "amina.h"))
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Route destination · dark") {
    NavigationStack {
        RouteDestinationView(route: .space(slug: "ibu-robotics"))
    }
    .preferredColorScheme(.dark)
    .environment(AuthSessionStore(container: .preview()))
}
