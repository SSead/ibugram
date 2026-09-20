import SwiftUI
import UIKit
import IBUgramKit

struct PostAuthorRow: View {
    let post: Post
    var onAuthor: () -> Void = {}
    var onDelete: (() -> Void)? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            Button(action: onAuthor) {
                AvatarView(
                    url: post.author.avatarURL,
                    displayName: post.author.displayName,
                    size: .small,
                    showsVerifiedBadge: isFaculty
                )
            }
            .accessibilityLabel("Open \(post.author.displayName)'s profile")

            VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                HStack(spacing: theme.spacing.xxs) {
                    Button(action: onAuthor) {
                        Text(post.author.displayName)
                            .font(theme.typography.bodyEmphasis)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    if isFaculty {
                        VerifiedBadge()
                            .font(theme.typography.caption)
                    }
                }
                metaRow
            }

            Spacer(minLength: theme.spacing.xs)

            if hasMenu {
                overflowMenu
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }

    private var hasMenu: Bool {
        onDelete != nil || !(post.caption?.isEmpty ?? true)
    }

    private var metaRow: some View {
        HStack(spacing: theme.spacing.xxs) {
            Text("@\(post.author.username)")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
                .lineLimit(1)
            Text("·")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
                .accessibilityHidden(true)
            Text(RelativeTimestamp.abbreviated(from: post.createdAt))
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
                .accessibilityLabel(RelativeTimestamp.accessible(from: post.createdAt))
        }
    }

    private var isFaculty: Bool {
        post.author.role == .faculty || post.author.isVerified
    }

    private var overflowMenu: some View {
        Menu {
            if let caption = post.caption, !caption.isEmpty {
                Button("Copy caption") {
                    UIPasteboard.general.string = caption
                }
            }
            if let onDelete {
                Button("Delete post", role: .destructive, action: onDelete)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(theme.spacing.xxs)
                .contentShape(.rect)
        }
        .accessibilityLabel("More actions")
    }
}
