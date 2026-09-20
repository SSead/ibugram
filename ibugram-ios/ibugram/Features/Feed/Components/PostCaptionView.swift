import SwiftUI
import IBUgramKit

struct PostCaptionView: View {
    let post: Post
    var onHashtag: (String) -> Void = { _ in }
    var onMention: (String) -> Void = { _ in }
    var onAuthor: () -> Void = {}

    @Environment(\.theme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            captionBlock
            if shouldOfferExpansion, !isExpanded {
                Button("more") { isExpanded = true }
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textTertiary)
                    .accessibilityLabel("Show more of the caption")
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.top, theme.spacing.xxs)
    }

    private var captionBlock: some View {
        Group {
            Text(post.author.username)
                .font(theme.typography.bodyEmphasis)
                .foregroundStyle(theme.colors.textPrimary)
            + Text(" ")
            + highlightedCaption
        }
        .lineLimit(isExpanded ? nil : 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .environment(\.openURL, OpenURLAction(handler: handleLink))
        .onTapGesture(perform: onAuthor)
    }

    private var highlightedCaption: Text {
        guard let caption = post.caption else { return Text("") }
        return CaptionTokenizer.tokens(in: caption).reduce(Text("")) { partial, token in
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
            Text(AttributedString("#\(tag)", attributes: linkAttributes(host: "hashtag", path: tag)))
                .font(theme.typography.bodyEmphasis)
        case .mention(let username):
            Text(AttributedString("@\(username)", attributes: linkAttributes(host: "mention", path: username)))
                .font(theme.typography.bodyEmphasis)
        }
    }

    private func linkAttributes(host: String, path: String) -> AttributeContainer {
        var attributes = AttributeContainer()
        attributes.link = URL(string: "ibugram://\(host)/\(path)")
        attributes.foregroundColor = theme.colors.brand
        attributes.underlineStyle = .none
        return attributes
    }

    private func handleLink(_ url: URL) -> OpenURLAction.Result {
        guard url.scheme == "ibugram" else { return .systemAction }
        let value = url.path.split(separator: "/").last.map(String.init) ?? url.host ?? ""
        switch url.host {
        case "hashtag":
            onHashtag(value)
            return .handled
        case "mention":
            onMention(value)
            return .handled
        default:
            return .discarded
        }
    }

    private var shouldOfferExpansion: Bool {
        (post.caption?.count ?? 0) > 140
    }
}
