import SwiftUI

struct ProfilePlaceholderView: View {
    @Environment(Router.self) private var router

    var body: some View {
        TeamHandoffView(
            tab: .profile,
            owner: "Profiles & Social Graph",
            brief: "Own profile header, post grid, saved and tagged tabs, followers and following lists.",
            entryPoint: "ibugram/Features/Profile/ProfilePlaceholderView.swift",
            sampleRoutes: [
                ("Open followers", .followers(username: SampleData.amina.username)),
                ("Open saved posts", .savedPosts)
            ]
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.settings) } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
    }
}

#Preview("Profile tab") {
    TabNavigationStack { ProfilePlaceholderView() }
        .appContainer(.preview())
}

#Preview("Profile tab · dark") {
    TabNavigationStack { ProfilePlaceholderView() }
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
