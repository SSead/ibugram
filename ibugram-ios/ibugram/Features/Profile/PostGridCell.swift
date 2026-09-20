import SwiftUI

struct PostGridCell: View {
    let post: Post

    @Environment(\.theme) private var theme

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { image }
            .clipped()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var image: some View {
        if let cover = post.cover {
            RemoteImage(
                url: cover.thumbnailUrl,
                blurhash: cover.blurhash,
                altText: cover.altText ?? post.caption,
                contentMode: .fill
            )
        } else {
            theme.colors.surfaceSunken
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(theme.colors.textTertiary)
                }
        }
    }

    private var accessibilityLabel: String {
        post.cover?.altText ?? post.caption ?? "Post"
    }
}

#Preview("Post grid cell") {
    PostGridCell(post: ProfileFixtures.posts[0])
        .frame(width: 120)
        .appContainer(.preview())
}
