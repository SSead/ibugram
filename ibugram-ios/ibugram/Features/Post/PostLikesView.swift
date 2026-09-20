import SwiftUI
import IBUgramKit

struct PostLikesView: View {
    let postID: UUID

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: PostLikesViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Likes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? PostLikesViewModel(api: container.api, postID: postID)
            viewModel = model
            await model.load()
        }
    }

    private func content(_ viewModel: PostLikesViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            if viewModel.isInitialLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading likes")
            } else if viewModel.isEmpty {
                EmptyStateView(
                    systemImage: "heart",
                    title: "No likes yet",
                    message: "When people like this post, they will show up here."
                )
            } else if case .failed(let error) = viewModel.phase, viewModel.users.isEmpty {
                ErrorStateView(error: error, retry: { await viewModel.reload() })
            } else {
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.users) { user in
                        likeRow(user)
                            .onAppear {
                                if user.id == viewModel.users.last?.id {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                    }
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding(theme.spacing.md)
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }

    private func likeRow(_ user: User) -> some View {
        Button {
            router.push(.profile(username: user.username))
        } label: {
            HStack(spacing: theme.spacing.sm) {
                AvatarView(
                    url: user.avatarURL,
                    displayName: user.displayName,
                    size: .medium,
                    showsVerifiedBadge: user.role == .faculty || user.isVerified
                )
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    Text(user.displayName)
                        .font(theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text("@\(user.username)")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(user.displayName), @\(user.username)")
    }
}

#Preview("Likes") {
    TabNavigationStack {
        PostLikesView(postID: FeedFixtures.singleImage.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
}

#Preview("Likes · empty") {
    TabNavigationStack {
        PostLikesView(postID: FeedFixtures.singleImage.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: [
        "GET /posts/\(FeedFixtures.singleImage.id)/likes": Paginated<User>(items: [])
    ])))
}

#Preview("Likes · dark") {
    TabNavigationStack {
        PostLikesView(postID: FeedFixtures.liked.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
    .preferredColorScheme(.dark)
}
