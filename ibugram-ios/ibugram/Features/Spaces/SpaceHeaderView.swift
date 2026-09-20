import SwiftUI
import IBUgramKit

struct SpaceHeaderView: View {
    let space: Space
    var isMutating = false
    var onMembers: () -> Void
    var onJoin: () -> Void
    var onLeave: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            banner
            identity
            if let description = space.description, !description.isEmpty {
                Text(description)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            metaRow
            SpaceJoinButton(space: space, isMutating: isMutating, onJoin: onJoin, onLeave: onLeave)
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.lg)
    }

    @ViewBuilder
    private var banner: some View {
        Color.clear
            .aspectRatio(2, contentMode: .fit)
            .overlay {
                if let url = space.bannerURL {
                    RemoteImage(url: url, altText: "\(space.name) banner", contentMode: .fill)
                } else {
                    theme.colors.brandMuted
                        .overlay {
                            Image(systemName: "person.3.fill")
                                .font(theme.typography.displaySmall)
                                .foregroundStyle(theme.colors.brand)
                        }
                }
            }
            .clipShape(.rect(cornerRadius: theme.radii.md))
            .accessibilityHidden(space.bannerURL == nil)
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            AvatarView(url: space.avatarResourceURL, displayName: space.name, size: .large)
            VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                HStack(spacing: theme.spacing.xxs) {
                    Text(space.name)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textPrimary)
                    if space.isOfficial {
                        TagChip(title: "Official", icon: "checkmark.seal.fill", style: .accent)
                    }
                }
                Text("/\(space.slug)")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(identityLabel)
    }

    private var metaRow: some View {
        HStack(spacing: theme.spacing.xs) {
            TagChip(title: space.kind.title, style: .brand)
            TagChip(title: space.visibility.title, style: .neutral)
            Button(action: onMembers) {
                Text(memberLabel)
                    .font(theme.typography.subheadline)
                    .foregroundStyle(theme.colors.brand)
            }
            .accessibilityLabel("\(space.memberCount) members")
            .accessibilityHint("View members")
        }
    }

    private var memberLabel: String {
        space.memberCount == 1 ? "1 member" : "\(space.memberCount) members"
    }

    private var identityLabel: String {
        var parts = [space.name, space.kind.title]
        if space.isOfficial { parts.insert("Official", at: 1) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Space header") {
    ScrollView {
        SpaceHeaderView(space: SpaceFixtures.robotics, onMembers: {}, onJoin: {}, onLeave: {})
    }
    .appContainer(.preview())
}
