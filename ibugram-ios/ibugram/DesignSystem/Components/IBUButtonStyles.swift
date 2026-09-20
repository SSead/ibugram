import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isLoading = false

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ButtonSurface(
            configuration: configuration,
            isLoading: isLoading,
            foreground: theme.colors.textOnBrand,
            background: theme.colors.brand,
            border: nil,
            isEnabled: isEnabled
        )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isLoading = false

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ButtonSurface(
            configuration: configuration,
            isLoading: isLoading,
            foreground: theme.colors.brand,
            background: theme.colors.brandMuted,
            border: theme.colors.brand.opacity(0.25),
            isEnabled: isEnabled
        )
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    var isLoading = false

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ButtonSurface(
            configuration: configuration,
            isLoading: isLoading,
            foreground: theme.colors.destructive,
            background: theme.colors.destructive.opacity(0.12),
            border: theme.colors.destructive.opacity(0.3),
            isEnabled: isEnabled
        )
    }
}

private struct ButtonSurface: View {
    let configuration: ButtonStyle.Configuration
    let isLoading: Bool
    let foreground: Color
    let background: Color
    let border: Color?
    let isEnabled: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(foreground)
            }
            configuration.label
                .font(theme.typography.headline)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.md)
        .padding(.horizontal, theme.spacing.lg)
        .background(background, in: .rect(cornerRadius: theme.radii.md))
        .overlay {
            if let border {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(border, lineWidth: 1)
            }
        }
        .opacity(isEnabled && !isLoading ? 1 : 0.55)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(theme.motion.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var ibuPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func ibuPrimary(isLoading: Bool) -> PrimaryButtonStyle { PrimaryButtonStyle(isLoading: isLoading) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var ibuSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func ibuSecondary(isLoading: Bool) -> SecondaryButtonStyle { SecondaryButtonStyle(isLoading: isLoading) }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var ibuDestructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

private struct ButtonGallery: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Button("Continue") {}.buttonStyle(.ibuPrimary)
            Button("Sending code") {}.buttonStyle(.ibuPrimary(isLoading: true))
            Button("Resend code") {}.buttonStyle(.ibuSecondary)
            Button("Sign out") {}.buttonStyle(.ibuDestructive)
            Button("Disabled") {}.buttonStyle(.ibuPrimary).disabled(true)
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.background)
    }
}

#Preview("Buttons") {
    ButtonGallery()
}

#Preview("Buttons · dark") {
    ButtonGallery()
        .preferredColorScheme(.dark)
}
