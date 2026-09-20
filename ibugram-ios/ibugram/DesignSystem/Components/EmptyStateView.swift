import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(theme.colors.brand.opacity(0.8))
                .padding(.bottom, theme.spacing.xxs)

            Text(title)
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textPrimary)

            Text(message)
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.ibuSecondary)
                    .padding(.top, theme.spacing.xs)
                    .frame(maxWidth: 260)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Empty state") {
    EmptyStateView(
        systemImage: "photo.on.rectangle.angled",
        title: "Nothing here yet",
        message: "Follow a few classmates and their posts will show up in this feed.",
        actionTitle: "Find people",
        action: {}
    )
}

#Preview("Empty state · dark") {
    EmptyStateView(
        systemImage: "bell.slash",
        title: "No activity",
        message: "Likes, comments and follows will appear here."
    )
    .preferredColorScheme(.dark)
}
