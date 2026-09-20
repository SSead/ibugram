import SwiftUI

struct SearchIdleView: View {
    let trending: [Hashtag]
    let suggested: [User]
    let recents: RecentSearchStore
    var onHashtag: (Hashtag) -> Void
    var onUser: (User) -> Void
    var onRecent: (String) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                if !recents.items.isEmpty { recentsSection }
                if !trending.isEmpty { trendingSection }
                if !suggested.isEmpty { suggestedSection }
            }
            .padding(.vertical, theme.spacing.sm)
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            SectionHeader(title: "Recent", actionTitle: "Clear all") {
                recents.clear()
            }
            ForEach(recents.items, id: \.self) { item in
                HStack {
                    Button {
                        onRecent(item)
                    } label: {
                        HStack(spacing: theme.spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(theme.colors.textTertiary)
                            Text(item)
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.textPrimary)
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Recent search, \(item)")

                    Button {
                        recents.remove(item)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(theme.colors.textTertiary)
                            .padding(theme.spacing.xxs)
                    }
                    .accessibilityLabel("Remove \(item) from recent searches")
                }
                .padding(.horizontal, theme.spacing.screenMargin)
                .padding(.vertical, theme.spacing.xxs)
            }
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            SectionHeader(title: "Trending hashtags")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(trending) { tag in
                        Button {
                            onHashtag(tag)
                        } label: {
                            TagChip(title: tag.displayTag, style: .brand)
                        }
                        .accessibilityLabel("\(tag.displayTag), \(tag.postCount) posts")
                    }
                }
                .padding(.horizontal, theme.spacing.screenMargin)
            }
        }
    }

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            SectionHeader(title: "Suggested people")
            ForEach(suggested) { user in
                FollowListRow(user: user, showsFollowButton: false, onOpen: { onUser(user) }, onToggleFollow: {})
            }
        }
    }
}

#Preview("Idle search") {
    SearchIdleView(
        trending: SearchFixtures.trending,
        suggested: [ProfileFixtures.followedStudent, ProfileFixtures.unfollowedFaculty],
        recents: RecentSearchStore(defaults: UserDefaults(suiteName: "ibugram.preview.recents") ?? .standard),
        onHashtag: { _ in },
        onUser: { _ in },
        onRecent: { _ in }
    )
    .appContainer(.preview())
}
