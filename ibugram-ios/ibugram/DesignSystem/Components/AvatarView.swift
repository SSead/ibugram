import SwiftUI

struct AvatarView: View {
    enum Size: Sendable {
        case small
        case medium
        case large
        case extraLarge

        var dimension: CGFloat {
            switch self {
            case .small: 32
            case .medium: 44
            case .large: 72
            case .extraLarge: 112
            }
        }

        var initialsFont: Font {
            switch self {
            case .small: .system(.caption, design: .rounded, weight: .semibold)
            case .medium: .system(.subheadline, design: .rounded, weight: .semibold)
            case .large: .system(.title2, design: .rounded, weight: .semibold)
            case .extraLarge: .system(.largeTitle, design: .rounded, weight: .semibold)
            }
        }
    }

    let url: URL?
    var displayName: String?
    var size: Size = .medium
    var showsVerifiedBadge = false

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            if url != nil {
                RemoteImage(url: url, altText: accessibilityDescription, contentMode: .fill)
            } else {
                fallback
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(theme.colors.separator, lineWidth: 0.5)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsVerifiedBadge {
                VerifiedBadge()
                    .font(.system(size: size.dimension * 0.3))
                    .background(theme.colors.background, in: .circle)
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [theme.colors.brand, theme.colors.brandContrast],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let initials {
                Text(initials)
                    .font(size.initialsFont)
                    .foregroundStyle(theme.colors.textOnBrand)
            } else {
                Image(systemName: "person.fill")
                    .font(size.initialsFont)
                    .foregroundStyle(theme.colors.textOnBrand)
            }
        }
    }

    private var initials: String? {
        guard let displayName else { return nil }
        let letters = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
        return letters.isEmpty ? nil : letters.joined().uppercased()
    }

    private var accessibilityDescription: String {
        displayName.map { "Profile photo of \($0)" } ?? "Profile photo"
    }
}

private struct AvatarGallery: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                AvatarView(url: nil, displayName: "Amina Hodžić", size: .small)
                AvatarView(url: nil, displayName: "Amina Hodžić", size: .medium)
                AvatarView(url: nil, displayName: "Damir Kovač", size: .large, showsVerifiedBadge: true)
            }
            AvatarView(url: nil, displayName: nil, size: .extraLarge)
        }
        .padding(32)
    }
}

#Preview("Avatar") {
    AvatarGallery()
}

#Preview("Avatar · dark") {
    AvatarGallery()
        .preferredColorScheme(.dark)
}
