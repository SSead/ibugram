import SwiftUI

struct TagChip: View {
    enum Style: Equatable {
        case neutral
        case brand
        case accent
    }

    let title: String
    var icon: String?
    var style: Style = .neutral
    var isSelected = false

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(theme.typography.caption)
            }
            Text(title)
                .font(theme.typography.captionEmphasis)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs + 2)
        .background(background, in: .capsule)
        .overlay {
            Capsule().strokeBorder(foreground.opacity(isSelected ? 0.45 : 0.15), lineWidth: 1)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var foreground: Color {
        switch style {
        case .neutral: theme.colors.textSecondary
        case .brand: theme.colors.brand
        case .accent: theme.colors.accent
        }
    }

    private var background: Color {
        switch style {
        case .neutral: theme.colors.surfaceSunken
        case .brand: theme.colors.brandMuted
        case .accent: theme.colors.accent.opacity(0.14)
        }
    }
}

private struct ChipGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TagChip(title: "#burchlife", style: .brand)
                TagChip(title: "IBU Robotics", icon: "person.3.fill", style: .brand)
                TagChip(title: "Official", icon: "checkmark.seal.fill", style: .accent)
            }
            HStack {
                TagChip(title: "Software Engineering", style: .neutral)
                TagChip(title: "Year 4", style: .neutral, isSelected: true)
            }
        }
        .padding(20)
    }
}

#Preview("Chips") {
    ChipGallery()
}

#Preview("Chips · dark") {
    ChipGallery()
        .preferredColorScheme(.dark)
}
