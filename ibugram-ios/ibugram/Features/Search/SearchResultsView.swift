import SwiftUI
import IBUgramKit

struct SearchResultsView: View {
    let viewModel: SearchViewModel

    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router

    var body: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .searching:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Searching")
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.flushPendingSearch() }
        case .results where viewModel.showsEmptyResults:
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No results",
                message: "Nothing matched “\(viewModel.trimmedQuery)”. Try a different name, tag or Space."
            )
        case .results:
            results
        }
    }

    @ViewBuilder
    private var results: some View {
        if viewModel.scope == .posts {
            postGrid
        } else {
            mixedList
        }
    }

    private var postGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.hairline), count: 3),
                spacing: theme.spacing.hairline
            ) {
                ForEach(viewModel.results.posts) { post in
                    Button {
                        router.push(.post(id: post.id))
                    } label: {
                        PostGridCell(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var mixedList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.spacing.md) {
                if !viewModel.results.users.isEmpty {
                    section("People") {
                        ForEach(viewModel.results.users) { user in
                            FollowListRow(
                                user: user,
                                showsFollowButton: false,
                                onOpen: { router.push(.profile(username: user.username)) },
                                onToggleFollow: {}
                            )
                        }
                    }
                }
                if !viewModel.results.hashtags.isEmpty {
                    section("Hashtags") {
                        ForEach(viewModel.results.hashtags) { tag in
                            SearchHashtagRow(hashtag: tag) {
                                router.push(.hashtag(tag: tag.tag))
                            }
                        }
                    }
                }
                if !viewModel.results.spaces.isEmpty {
                    section("Spaces") {
                        ForEach(viewModel.results.spaces) { space in
                            SearchSpaceRow(space: space) {
                                router.push(.space(slug: space.slug))
                            }
                        }
                    }
                }
                if viewModel.scope == .all, !viewModel.results.posts.isEmpty {
                    section("Posts") {
                        postGrid
                    }
                }
            }
            .padding(.vertical, theme.spacing.sm)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            SectionHeader(title: title)
            content()
        }
    }
}
