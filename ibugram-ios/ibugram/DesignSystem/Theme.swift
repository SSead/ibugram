import SwiftUI

struct Theme: Sendable {
    let colors: ThemeColors
    let typography: ThemeTypography
    let spacing: ThemeSpacing
    let radii: ThemeRadii
    let shadows: ThemeShadows
    let motion: ThemeMotion

    static let ibu = Theme(
        colors: ThemeColors(),
        typography: ThemeTypography(),
        spacing: ThemeSpacing(),
        radii: ThemeRadii(),
        shadows: ThemeShadows(),
        motion: ThemeMotion()
    )
}

struct ThemeColors: Sendable {
    let brand = Color(.brandPrimary)
    let brandMuted = Color(.brandMuted)
    let brandContrast = Color(.brandContrast)
    let accent = Color(.brandAccent)

    let background = Color(.surfaceBackground)
    let surface = Color(.surfaceRaised)
    let surfaceSunken = Color(.surfaceSunken)
    let separator = Color(.surfaceSeparator)

    let textPrimary = Color(.contentPrimary)
    let textSecondary = Color(.contentSecondary)
    let textTertiary = Color(.contentTertiary)
    let textOnBrand = Color(.contentOnBrand)

    let destructive = Color(.stateDestructive)
    let success = Color(.stateSuccess)
    let warning = Color(.stateWarning)

    let skeletonBase = Color(.skeletonBase)
    let skeletonHighlight = Color(.skeletonHighlight)
}

struct ThemeTypography: Sendable {
    let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .bold)
    let displaySmall = Font.system(.title, design: .rounded, weight: .bold)
    let titleLarge = Font.system(.title2, design: .rounded, weight: .semibold)
    let titleSmall = Font.system(.title3, design: .rounded, weight: .semibold)
    let headline = Font.system(.headline, design: .default, weight: .semibold)
    let body = Font.system(.body)
    let bodyEmphasis = Font.system(.body, design: .default, weight: .semibold)
    let callout = Font.system(.callout)
    let subheadline = Font.system(.subheadline)
    let footnote = Font.system(.footnote)
    let caption = Font.system(.caption)
    let captionEmphasis = Font.system(.caption, design: .default, weight: .semibold)
    let monospacedCode = Font.system(.title2, design: .monospaced, weight: .semibold)
}

struct ThemeSpacing: Sendable {
    let hairline: CGFloat = 2
    let xxs: CGFloat = 4
    let xs: CGFloat = 8
    let sm: CGFloat = 12
    let md: CGFloat = 16
    let lg: CGFloat = 20
    let xl: CGFloat = 24
    let xxl: CGFloat = 32
    let xxxl: CGFloat = 48
    let screenMargin: CGFloat = 20
}

struct ThemeRadii: Sendable {
    let xs: CGFloat = 6
    let sm: CGFloat = 10
    let md: CGFloat = 14
    let lg: CGFloat = 20
    let xl: CGFloat = 28
    let pill: CGFloat = 999
}

struct ThemeShadows: Sendable {
    struct Shadow: Sendable {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    let subtle = Shadow(color: Color(.shadowTint).opacity(0.10), radius: 4, x: 0, y: 2)
    let card = Shadow(color: Color(.shadowTint).opacity(0.14), radius: 12, x: 0, y: 6)
    let elevated = Shadow(color: Color(.shadowTint).opacity(0.20), radius: 24, x: 0, y: 12)
}

struct ThemeMotion: Sendable {
    let quick = Animation.spring(response: 0.22, dampingFraction: 0.86)
    let standard = Animation.spring(response: 0.35, dampingFraction: 0.82)
    let emphasis = Animation.spring(response: 0.5, dampingFraction: 0.72)
    let shimmer = Animation.linear(duration: 1.25).repeatForever(autoreverses: false)
}

extension View {
    func shadow(_ shadow: ThemeShadows.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension EnvironmentValues {
    @Entry var theme: Theme = .ibu
}
