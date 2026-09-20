import SwiftUI

struct OnboardingAvatarPreview: View {
    let imageData: Data?
    let displayName: String

    @Environment(\.theme) private var theme

    var body: some View {
        preview
            .overlay(alignment: .bottomTrailing) { cameraBadge }
    }

    @ViewBuilder
    private var preview: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 112, height: 112)
                .clipShape(.circle)
        } else {
            AvatarView(
                url: nil,
                displayName: displayName.isEmpty ? nil : displayName,
                size: .extraLarge
            )
        }
    }

    private var cameraBadge: some View {
        Image(systemName: "camera.fill")
            .font(theme.typography.footnote)
            .foregroundStyle(theme.colors.textOnBrand)
            .padding(theme.spacing.xs)
            .background(theme.colors.brand, in: .circle)
    }
}

#Preview("Avatar preview") {
    OnboardingAvatarPreview(imageData: nil, displayName: "Amina Hodžić")
        .padding()
}

#Preview("Avatar preview · dark") {
    OnboardingAvatarPreview(imageData: nil, displayName: "")
        .padding()
        .preferredColorScheme(.dark)
}
