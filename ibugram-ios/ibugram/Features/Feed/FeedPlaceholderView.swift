import SwiftUI

struct FeedPlaceholderView: View {
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router

    var body: some View {
        TeamHandoffView(
            tab: .feed,
            owner: "Feed & Posts",
            brief: "Following and Discover feeds, post cards, likes, saves and the comment thread.",
            entryPoint: "ibugram/Features/Feed/FeedPlaceholderView.swift",
            sampleRoutes: [
                ("Open a post", .post(id: SampleData.amina.id)),
                ("Open a hashtag", .hashtag(tag: "burchlife"))
            ]
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BrandWordmark(height: 22)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.messageRequests) } label: {
                    Image(systemName: "paperplane")
                }
                .accessibilityLabel("Direct messages")
            }
        }
        .background(theme.colors.background)
    }
}

#Preview("Feed tab") {
    TabNavigationStack { FeedPlaceholderView() }
        .appContainer(.preview())
}

#Preview("Feed tab · dark") {
    TabNavigationStack { FeedPlaceholderView() }
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
