import SwiftUI
import IBUgramKit

struct CommentComposerBar: View {
    @Binding var text: String
    var isSending: Bool
    var commentsEnabled: Bool
    var replyingTo: Comment?
    var onSend: () -> Void
    var onCancelReply: () -> Void

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo {
                HStack {
                    Text("Replying to @\(replyingTo.author.username)")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                    Button("Cancel", action: onCancelReply)
                        .font(theme.typography.captionEmphasis)
                        .foregroundStyle(theme.colors.brand)
                        .accessibilityLabel("Cancel reply")
                }
                .padding(.horizontal, theme.spacing.screenMargin)
                .padding(.top, theme.spacing.xs)
            }

            if commentsEnabled {
                field
            } else {
                Text("Comments are turned off on this post.")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textTertiary)
                    .padding(theme.spacing.md)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(theme.colors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.colors.separator)
                .frame(height: theme.spacing.hairline / 2)
        }
    }

    private var field: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.xs) {
            TextField("Add a comment…", text: $text, axis: .vertical)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1...4)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit(onSend)
                .accessibilityLabel("Comment")

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(canSend ? theme.colors.brand : theme.colors.textTertiary)
            }
            .disabled(!canSend)
            .accessibilityLabel("Post comment")
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.sm)
        .opacity(isSending ? 0.6 : 1)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
}

#Preview("Composer bar") {
    CommentComposerBar(
        text: .constant("Looks great"),
        isSending: false,
        commentsEnabled: true,
        replyingTo: PostFixtures.rootComment,
        onSend: {},
        onCancelReply: {}
    )
    .appContainer(.preview())
}
