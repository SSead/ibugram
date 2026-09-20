import SwiftUI

struct VerifiedBadge: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .foregroundStyle(theme.colors.brand)
            .accessibilityLabel("Verified faculty account")
    }
}

#Preview("Verified badge") {
    HStack {
        Text("Prof. Dr. Damir Kovač")
        VerifiedBadge()
    }
    .padding()
}

#Preview("Verified badge · dark") {
    HStack {
        Text("Prof. Dr. Damir Kovač")
        VerifiedBadge()
    }
    .padding()
    .preferredColorScheme(.dark)
}
