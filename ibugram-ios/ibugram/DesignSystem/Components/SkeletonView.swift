import SwiftUI

struct SkeletonView: View {
    var cornerRadius: CGFloat?

    @Environment(\.theme) private var theme

    var body: some View {
        theme.colors.skeletonBase
            .clipShape(.rect(cornerRadius: cornerRadius ?? theme.radii.xs))
            .shimmering()
            .accessibilityHidden(true)
    }
}

struct PostCardSkeleton: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                SkeletonView(cornerRadius: theme.radii.pill)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    SkeletonView().frame(width: 130, height: 12)
                    SkeletonView().frame(width: 80, height: 10)
                }
            }
            SkeletonView(cornerRadius: theme.radii.md)
                .frame(height: 260)
            SkeletonView().frame(height: 12)
            SkeletonView().frame(width: 200, height: 12)
        }
        .padding(theme.spacing.md)
    }
}

#Preview("Skeletons") {
    VStack { PostCardSkeleton(); PostCardSkeleton() }
}

#Preview("Skeletons · dark") {
    VStack { PostCardSkeleton(); PostCardSkeleton() }
        .preferredColorScheme(.dark)
}
