import SwiftUI

struct ComposerPlaceholderView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.md) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(theme.colors.brand)
                Text("Composer")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("Image picker, crop, caption with on-device alt-text and hashtag suggestions, Space and Event attachment.")
                    .font(theme.typography.subheadline)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                TagChip(title: "Owned by Composer & Intelligence", icon: "sparkles", style: .brand)
                Text("ibugram/Features/Create/ComposerPlaceholderView.swift")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
                    .textSelection(.enabled)
            }
            .padding(theme.spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background)
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview("Composer") {
    ComposerPlaceholderView()
        .appContainer(.preview())
}

#Preview("Composer · dark") {
    ComposerPlaceholderView()
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
