import SwiftUI

struct SearchPlaceholderView: View {
    var body: some View {
        TeamHandoffView(
            tab: .search,
            owner: "Search & Discovery",
            brief: "Unified search over users, hashtags, Spaces and captions, plus trending and suggestions.",
            entryPoint: "ibugram/Features/Search/SearchPlaceholderView.swift",
            sampleRoutes: [
                ("Open a profile", .profile(username: SampleData.amina.username)),
                ("Open a Space", .space(slug: "ibu-robotics"))
            ]
        )
    }
}

#Preview("Search tab") {
    TabNavigationStack { SearchPlaceholderView() }
        .appContainer(.preview())
}

#Preview("Search tab · dark") {
    TabNavigationStack { SearchPlaceholderView() }
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
