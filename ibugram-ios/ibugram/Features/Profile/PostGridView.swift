import SwiftUI
import IBUgramKit

struct PostGridView: View {
    let posts: PagedList<Post>
    var emptyTitle: String
    var emptyMessage: String
    var onSelect: (Post) -> Void

    @Environment(\.theme) private var theme

    private let columnCount = 3

    var body: some View {
        switch posts.phase {
        case .idle, .loading:
            grid(placeholderCount: 9, isPlaceholder: true)
        case .failed(let error):
            ErrorStateView(error: error) { await posts.reload() }
                .padding(.top, theme.spacing.xl)
        case .loaded where posts.isEmpty:
            EmptyStateView(systemImage: "photo.on.rectangle.angled", title: emptyTitle, message: emptyMessage)
                .padding(.top, theme.spacing.xl)
        case .loaded:
            grid(placeholderCount: 0, isPlaceholder: false)
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: theme.spacing.hairline), count: columnCount)
    }

    private func grid(placeholderCount: Int, isPlaceholder: Bool) -> some View {
        LazyVGrid(columns: columns, spacing: theme.spacing.hairline) {
            if isPlaceholder {
                ForEach(0..<placeholderCount, id: \.self) { _ in
                    SkeletonView(cornerRadius: 0)
                        .aspectRatio(1, contentMode: .fit)
                }
            } else {
                ForEach(posts.items) { post in
                    Button {
                        onSelect(post)
                    } label: {
                        PostGridCell(post: post)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if post.id == posts.items.last?.id {
                            Task { await posts.loadNextPage() }
                        }
                    }
                }
            }
        }
    }
}

#Preview("Post grid") {
    let posts = PagedList<Post> { _ in Paginated(items: ProfileFixtures.posts) }
    return ScrollView {
        PostGridView(
            posts: posts,
            emptyTitle: "No posts yet",
            emptyMessage: "When you share a photo it will show up here.",
            onSelect: { _ in }
        )
    }
    .appContainer(.preview())
    .task { await posts.loadFirstPageIfNeeded() }
}
