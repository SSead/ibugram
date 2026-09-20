import SwiftUI

struct PostDetailView: View {
    let postID: UUID

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: PostDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel = viewModel ?? PostDetailViewModel(api: container.api, postID: postID) }
        .task { await viewModel?.load() }
    }

    private func content(_ viewModel: PostDetailViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            if viewModel.isInitialLoading {
                ScrollView {
                    PostCardSkeleton()
                }
            } else if case .failed(let error) = viewModel.phase {
                ErrorStateView(error: error, retry: { await viewModel.reload() })
            } else {
                loadedContent(viewModel)
            }
        }
        .errorAlert(bound.presentedError)
        .safeAreaInset(edge: .bottom) {
            if let post = viewModel.post {
                CommentComposerBar(
                    text: bound.draft,
                    isSending: viewModel.isSendingComment,
                    commentsEnabled: post.commentsEnabled,
                    replyingTo: viewModel.replyingTo,
                    onSend: { Task { await viewModel.sendComment() } },
                    onCancelReply: viewModel.cancelReply
                )
            }
        }
    }

    private func loadedContent(_ viewModel: PostDetailViewModel) -> some View {
        RefreshableScrollView(refresh: { await viewModel.reload() }) {
            if let post = viewModel.post {
                PostCard(post: post, actions: actions(for: post, viewModel: viewModel))
            }
            comments(viewModel)
        }
    }

    @ViewBuilder
    private func comments(_ viewModel: PostDetailViewModel) -> some View {
        SectionHeader(title: "Comments")
        if let error = viewModel.commentsFailed, viewModel.comments.isEmpty {
            ErrorStateView(error: error, retry: { await viewModel.reload() })
        } else if viewModel.commentsAreEmpty {
            EmptyStateView(
                systemImage: "bubble.right",
                title: "No comments yet",
                message: "Start the thread. Be kind — this is campus."
            )
        } else {
            ForEach(viewModel.threadedComments) { thread in
                CommentRow(
                    comment: thread.comment,
                    canDelete: viewModel.canDelete(thread.comment),
                    onLike: { Task { await viewModel.toggleLike(on: thread.comment) } },
                    onReply: { viewModel.beginReply(to: thread.comment) },
                    onAuthor: { router.push(.profile(username: thread.comment.author.username)) },
                    onDelete: { Task { await viewModel.delete(thread.comment) } }
                )
                .padding(.horizontal, theme.spacing.screenMargin)
                .onAppear {
                    if thread.id == viewModel.threadedComments.last?.id {
                        Task { await viewModel.loadMoreComments() }
                    }
                }

                ForEach(thread.replies) { reply in
                    CommentRow(
                        comment: reply,
                        isReply: true,
                        canDelete: viewModel.canDelete(reply),
                        onLike: { Task { await viewModel.toggleLike(on: reply) } },
                        onReply: { viewModel.beginReply(to: reply) },
                        onAuthor: { router.push(.profile(username: reply.author.username)) },
                        onDelete: { Task { await viewModel.delete(reply) } }
                    )
                    .padding(.horizontal, theme.spacing.screenMargin)
                }
            }
            if viewModel.isLoadingMoreComments {
                ProgressView()
                    .padding(theme.spacing.md)
                    .accessibilityLabel("Loading more comments")
            }
        }
    }

    private func actions(for post: Post, viewModel: PostDetailViewModel) -> PostCardActions {
        PostCardActions(
            onLike: { Task { await viewModel.toggleLike() } },
            onDoubleTapLike: { Task { await viewModel.likeIfNeeded() } },
            onComment: {},
            onSave: { Task { await viewModel.toggleSave() } },
            onAuthor: { router.push(.profile(username: post.author.username)) },
            onHashtag: { router.push(.hashtag(tag: $0)) },
            onMention: { router.push(.profile(username: $0)) },
            onLikeCount: { router.push(.postLikes(postID: post.id)) }
        )
    }
}

#Preview("Post detail") {
    TabNavigationStack {
        PostDetailView(postID: FeedFixtures.singleImage.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
}

#Preview("Post detail · dark") {
    TabNavigationStack {
        PostDetailView(postID: FeedFixtures.facultyAuthor.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
    .preferredColorScheme(.dark)
}

#Preview("Post detail · empty comments") {
    TabNavigationStack {
        PostDetailView(postID: FeedFixtures.longCaption.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Post detail · error") {
    TabNavigationStack {
        PostDetailView(postID: FeedFixtures.singleImage.id)
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}
