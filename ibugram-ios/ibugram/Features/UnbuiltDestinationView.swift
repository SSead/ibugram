import SwiftUI

/// Marks an insertion point for a feature team. Every one of these is expected to be deleted.
struct UnbuiltDestinationView: View {
    let title: String
    let owner: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: "square.dashed")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(theme.colors.brand.opacity(0.7))
            Text(title)
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
            TagChip(title: "Owned by \(owner)", icon: "person.2.badge.gearshape", style: .brand)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Unbuilt destination") {
    NavigationStack {
        UnbuiltDestinationView(title: "Post detail", owner: "Feed & Posts")
    }
}

#Preview("Unbuilt destination · dark") {
    NavigationStack {
        UnbuiltDestinationView(title: "Post detail", owner: "Feed & Posts")
    }
    .preferredColorScheme(.dark)
}
