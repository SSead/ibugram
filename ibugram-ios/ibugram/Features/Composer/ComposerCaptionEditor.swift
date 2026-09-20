import SwiftUI

struct ComposerCaptionEditor: View {
    @Binding var caption: String
    let characterCount: Int
    let isOverLimit: Bool

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text("Caption")
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.6)

            ZStack(alignment: .topLeading) {
                highlightedCaption
                TextEditor(text: $caption)
                    .font(theme.typography.body)
                    .foregroundStyle(.clear)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .tint(theme.colors.brand)
                    .frame(minHeight: theme.spacing.xxxl + theme.spacing.xl)
                    .accessibilityLabel("Caption")
            }
            .padding(theme.spacing.sm)
            .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))
            .overlay {
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 1.6 : 1)
            }

            HStack {
                Text("Hashtags and @mentions highlight as you type.")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textTertiary)
                Spacer()
                Text("\(characterCount)/\(ComposerLimits.maximumCaptionLength)")
                    .font(theme.typography.caption)
                    .foregroundStyle(isOverLimit ? theme.colors.destructive : theme.colors.textTertiary)
                    .accessibilityLabel("\(characterCount) of \(ComposerLimits.maximumCaptionLength) characters")
            }
        }
    }

    private var highlightedCaption: some View {
        Text(caption.isEmpty ? "What is happening on campus?" : "")
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textTertiary)
            .overlay(alignment: .topLeading) {
                if !caption.isEmpty {
                    tokens
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
    }

    private var tokens: Text {
        CaptionTokenizer.tokens(in: caption).reduce(Text("")) { partial, token in
            partial + text(for: token)
        }
    }

    private func text(for token: CaptionToken) -> Text {
        switch token {
        case .text(let value):
            Text(value)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
        case .hashtag(let tag):
            Text("#\(tag)")
                .font(theme.typography.bodyEmphasis)
                .foregroundStyle(theme.colors.brand)
        case .mention(let username):
            Text("@\(username)")
                .font(theme.typography.bodyEmphasis)
                .foregroundStyle(theme.colors.brand)
        }
    }

    private var borderColor: Color {
        if isOverLimit { return theme.colors.destructive }
        return isFocused ? theme.colors.brand : theme.colors.separator
    }
}

#Preview("Caption editor") {
    ComposerCaptionEditor(caption: .constant("Hello #burch from @amina.h"), characterCount: 28, isOverLimit: false)
        .padding()
        .appContainer(.preview())
}
