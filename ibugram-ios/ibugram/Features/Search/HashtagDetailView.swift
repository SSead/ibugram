import SwiftUI

struct HashtagDetailView: View {
    let tag: String

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: HashtagDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                grid(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("#\(tag)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = viewModel ?? HashtagDetailViewModel(api: container.api, tag: tag)
        }
        .task { await viewModel?.load() }
    }

    private func grid(_ viewModel: HashtagDetailViewModel) -> some View {
        RefreshableScrollView(refresh: { await viewModel.reload() }) {
            PostGridView(
                posts: viewModel.posts,
                emptyTitle: "No posts yet",
                emptyMessage: "Nobody has used #\(tag) yet. Be the first.",
                onSelect: { router.push(.post(id: $0.id)) }
            )
        }
    }
}

#Preview("Hashtag") {
    TabNavigationStack {
        HashtagDetailView(tag: "robotics")
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Hashtag · dark") {
    TabNavigationStack {
        HashtagDetailView(tag: "robotics")
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
