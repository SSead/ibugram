import SwiftUI
import IBUgramKit

struct MessageRequestBanner: View {
    let senderName: String
    var isAccepting: Bool
    var onAccept: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Message request")
                .font(theme.typography.bodyEmphasis)
                .foregroundStyle(theme.colors.textPrimary)
            Text("\(senderName) isn’t in your inbox yet. Accept to move this thread there.")
                .font(theme.typography.footnote)
                .foregroundStyle(theme.colors.textSecondary)
            Button("Accept", action: onAccept)
                .buttonStyle(.ibuPrimary(isLoading: isAccepting))
                .accessibilityLabel("Accept message request from \(senderName)")
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.md))
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }
}

#Preview("Request banner") {
    MessageRequestBanner(senderName: "Prof. Dr. Damir Kovač", isAccepting: false, onAccept: {})
}
