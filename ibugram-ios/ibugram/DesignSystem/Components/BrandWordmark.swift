import SwiftUI

/// The university wordmark. The asset carries a light and a dark variant because the mark is
/// three fixed brand colours, not a tintable glyph.
struct BrandWordmark: View {
    var height: CGFloat = 34

    var body: some View {
        Image(.logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .accessibilityLabel("International Burch University")
    }
}

#Preview("Wordmark") {
    BrandWordmark(height: 58)
        .padding(40)
}

#Preview("Wordmark · dark") {
    BrandWordmark(height: 58)
        .padding(40)
        .preferredColorScheme(.dark)
}
