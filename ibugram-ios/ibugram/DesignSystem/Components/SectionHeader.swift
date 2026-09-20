import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                Text(title)
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            Spacer(minLength: theme.spacing.xs)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(theme.typography.subheadline)
                    .foregroundStyle(theme.colors.brand)
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Section header") {
    VStack(spacing: 0) {
        SectionHeader(title: "Happening now", subtitle: "3 events on campus", actionTitle: "See all", action: {})
        Divider()
        SectionHeader(title: "Suggested for you")
    }
}

#Preview("Section header · dark") {
    SectionHeader(title: "Happening now", subtitle: "3 events on campus", actionTitle: "See all", action: {})
        .preferredColorScheme(.dark)
}
