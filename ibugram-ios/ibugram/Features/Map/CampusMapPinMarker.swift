import SwiftUI

struct CampusMapPinMarker: View {
    let systemImage: String

    @Environment(\.theme) private var theme

    var body: some View {
        Image(systemName: systemImage)
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.textOnBrand)
            .padding(theme.spacing.xs)
            .background(theme.colors.brand, in: .circle)
            .shadow(theme.shadows.subtle)
    }
}

#Preview("Map pin") {
    HStack(spacing: 16) {
        CampusMapPinMarker(systemImage: "calendar")
        CampusMapPinMarker(systemImage: "photo")
    }
    .padding()
}
