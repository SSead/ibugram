import SwiftUI
import UIKit

struct ComposerImageRow: View {
    let image: ComposerDraftImage
    var canMoveUp = false
    var canMoveDown = false
    var onAltTextChange: (String) -> Void
    var onRemove: () -> Void
    var onRetry: () -> Void
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                thumbnail
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    status
                    TextField("Alt text", text: altTextBinding, axis: .vertical)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2...4)
                        .padding(theme.spacing.xs)
                        .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.xs))
                        .accessibilityLabel("Alt text")
                    if let suggested = image.suggestedAltText, suggested != image.altText, !suggested.isEmpty {
                        Text("Suggested: \(suggested)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textTertiary)
                    }
                }
                VStack(spacing: theme.spacing.xxs) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!canMoveUp)
                    .accessibilityLabel("Move photo up")
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!canMoveDown)
                    .accessibilityLabel("Move photo down")
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("Remove photo")
                }
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.md))
    }

    private var altTextBinding: Binding<String> {
        Binding(
            get: { image.altText },
            set: { newValue in onAltTextChange(newValue) }
        )
    }

    private var thumbnail: some View {
        ZStack {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                theme.colors.skeletonBase
            }
            if image.phase == .uploading {
                theme.colors.textPrimary.opacity(0.35)
                ProgressView(value: image.uploadProgress)
                    .progressViewStyle(.circular)
                    .tint(theme.colors.textOnBrand)
            }
        }
        .frame(width: theme.spacing.xxxl + theme.spacing.md, height: theme.spacing.xxxl + theme.spacing.md)
        .clipShape(.rect(cornerRadius: theme.radii.sm))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var status: some View {
        switch image.phase {
        case .pending:
            Text("Ready to upload")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
        case .uploading:
            Text("Uploading…")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
        case .uploaded:
            Text("Uploaded")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.success)
        case .failed:
            Button("Upload failed · Retry", action: onRetry)
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.destructive)
                .accessibilityLabel("Retry upload")
        }
    }
}

#Preview("Image row") {
    ComposerImageRow(
        image: ComposerFixtures.previewImage,
        onAltTextChange: { _ in },
        onRemove: {},
        onRetry: {}
    )
    .padding()
    .appContainer(.preview())
}
