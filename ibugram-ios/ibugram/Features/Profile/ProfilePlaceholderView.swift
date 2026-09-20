import SwiftUI

struct ProfilePlaceholderView: View {
    @Environment(AuthSessionStore.self) private var session

    var body: some View {
        if let username = session.currentUser?.username, !username.isEmpty {
            ProfileView(username: username)
        } else {
            ProfileView(
                username: ProfileFixtures.currentUser.username,
                previewCurrentUser: ProfileFixtures.currentUser
            )
        }
    }
}

#Preview("Profile tab") {
    TabNavigationStack { ProfilePlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Profile tab · dark") {
    TabNavigationStack { ProfilePlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
