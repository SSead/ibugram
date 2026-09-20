import SwiftUI

/// The IBUgram product mark: the university's initials on the brand gradient.
struct AppMarkView: View {
    var dimension: CGFloat = 76

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.colors.brand, theme.colors.brandContrast],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text("IBU")
                .font(.system(size: dimension * 0.34, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.colors.textOnBrand)
                .kerning(-0.5)
        }
        .frame(width: dimension, height: dimension)
        .clipShape(.rect(cornerRadius: dimension * 0.28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: dimension * 0.28, style: .continuous)
                .strokeBorder(theme.colors.textOnBrand.opacity(0.18), lineWidth: 1)
        }
        .shadow(theme.shadows.card)
        .accessibilityHidden(true)
    }
}

#Preview("App mark") {
    AppMarkView()
        .padding(40)
}

#Preview("App mark · dark") {
    AppMarkView()
        .padding(40)
        .preferredColorScheme(.dark)
}
