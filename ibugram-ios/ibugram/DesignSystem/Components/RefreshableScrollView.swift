import SwiftUI

/// The app's one pull-to-refresh container. Wrapping `.refreshable` here keeps the gesture,
/// spacing and scroll behaviour identical on every screen.
struct RefreshableScrollView<Content: View>: View {
    var showsIndicators = true
    let refresh: @Sendable () async -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            LazyVStack(spacing: theme.spacing.md) {
                content()
            }
            .padding(.vertical, theme.spacing.xs)
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { await refresh() }
        .background(theme.colors.background)
    }
}

#Preview("Pull to refresh") {
    RefreshableScrollView(refresh: {}) {
        ForEach(0..<4, id: \.self) { _ in PostCardSkeleton() }
    }
}

#Preview("Pull to refresh · dark") {
    RefreshableScrollView(refresh: {}) {
        ForEach(0..<4, id: \.self) { _ in PostCardSkeleton() }
    }
    .preferredColorScheme(.dark)
}
