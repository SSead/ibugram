import SwiftUI

struct FeedView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: FeedViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            }
        }
        .background(theme.colors.background)
        .onAppear { viewModel = viewModel ?? FeedViewModel(api: container.api) }
        .task { await viewModel?.load() }
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
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ viewModel: FeedViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            picker(viewModel)
            RefreshableScrollView(refresh: { await viewModel.reload() }) {
                HappeningNowRail(
                    events: viewModel.happeningNowEvents(),
                    onSelect: { router.push(.event(id: $0.id)) }
                )
                feedBody(viewModel)
            }
        }
        .errorAlert(bound.presentedError)
        .onChange(of: viewModel.selectedKind) {
            Task { await viewModel.load() }
        }
    }

    private func picker(_ viewModel: FeedViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Picker("Feed", selection: bound.selectedKind) {
            ForEach(FeedKind.allCases) { kind in
                Text(kind.title).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
        .accessibilityLabel("Feed source")
        .tint(theme.colors.brand)
    }

    @ViewBuilder
    private func feedBody(_ viewModel: FeedViewModel) -> some View {
        if viewModel.isInitialLoading {
            ForEach(0..<3, id: \.self) { _ in
                PostCardSkeleton()
            }
        } else if viewModel.isEmpty {
            EmptyStateView(
                systemImage: "photo.on.rectangle.angled",
                title: viewModel.selectedKind.emptyTitle,
                message: viewModel.selectedKind.emptyMessage
            )
        } else if case .failed(let error) = viewModel.phase, viewModel.displayPosts.isEmpty {
            ErrorStateView(error: error, retry: { await viewModel.reload() })
        } else {
            posts(viewModel)
        }
    }

    @ViewBuilder
    private func posts(_ viewModel: FeedViewModel) -> some View {
        ForEach(viewModel.displayPosts) { post in
            PostCard(post: post, actions: actions(for: post, viewModel: viewModel))
                .onAppear {
                    if post.id == viewModel.displayPosts.last?.id {
                        Task { await viewModel.loadNextPage() }
                    }
                }
        }
        if viewModel.isLoadingMore {
            ProgressView()
                .padding(theme.spacing.md)
                .accessibilityLabel("Loading more posts")
        }
    }

    private func actions(for post: Post, viewModel: FeedViewModel) -> PostCardActions {
        let isOwner = post.author.id == session.currentUser?.id
        return PostCardActions(
            onLike: { Task { await viewModel.toggleLike(of: post) } },
            onDoubleTapLike: { Task { await viewModel.likeIfNeeded(post) } },
            onComment: { router.push(.post(id: post.id)) },
            onSave: { Task { await viewModel.toggleSave(of: post) } },
            onAuthor: { router.push(.profile(username: post.author.username)) },
            onHashtag: { router.push(.hashtag(tag: $0)) },
            onMention: { router.push(.profile(username: $0)) },
            onLikeCount: { router.push(.postLikes(postID: post.id)) },
            onDelete: isOwner ? { Task { await viewModel.delete(post) } } : nil
        )
    }
}

#Preview("Feed") {
    TabNavigationStack { FeedView() }
        .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
}

#Preview("Feed · empty") {
    TabNavigationStack { FeedView() }
        .appContainer(.preview(api: MockAPIClient(stubs: [
            "GET /feed/following": Page<Post>(items: []),
            "GET /feed/discover": Page<Post>(items: [])
        ])))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Feed · offline") {
    TabNavigationStack { FeedView() }
        .appContainer(.preview(api: MockAPIClient.failing(.offline)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Feed · loading") {
    TabNavigationStack { FeedView() }
        .appContainer(.preview(api: MockAPIClient.loadingForever()))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Feed · dark") {
    TabNavigationStack { FeedView() }
        .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
        .preferredColorScheme(.dark)
}
