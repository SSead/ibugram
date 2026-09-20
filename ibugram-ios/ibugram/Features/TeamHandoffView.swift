import SwiftUI
import IBUgramKit

/// The body every tab placeholder shares: who owns the tab, what it becomes, and live proof that
/// pushing a `Route` works from here.
struct TeamHandoffView: View {
    let tab: AppTab
    let owner: String
    let brief: String
    let entryPoint: String
    var sampleRoutes: [(title: String, route: Route)] = []

    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                banner
                Text(brief)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                Text(entryPoint)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
                    .textSelection(.enabled)
                if !sampleRoutes.isEmpty {
                    routeButtons
                }
            }
            .padding(theme.spacing.screenMargin)
        }
        .background(theme.colors.background)
        .navigationTitle(tab.title)
    }

    private var banner: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: tab.systemImage)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textOnBrand)
                .frame(width: 52, height: 52)
                .background(theme.colors.brand, in: .rect(cornerRadius: theme.radii.md))
            VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                Text("\(tab.title) tab")
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("Owned by \(owner)")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }

    private var routeButtons: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            SectionHeader(title: "Navigation check")
                .padding(.horizontal, -theme.spacing.screenMargin)
            ForEach(Array(sampleRoutes.enumerated()), id: \.offset) { _, entry in
                Button(entry.title) { router.push(entry.route) }
                    .buttonStyle(.ibuSecondary)
            }
        }
    }
}

#Preview("Team handoff") {
    TabNavigationStack {
        TeamHandoffView(
            tab: .search,
            owner: "Search & Discovery",
            brief: "Unified search across users, hashtags, Spaces and captions.",
            entryPoint: "ibugram/Features/Search/SearchPlaceholderView.swift",
            sampleRoutes: [("Open a hashtag", .hashtag(tag: "burchlife"))]
        )
    }
    .appContainer(.preview())
}

#Preview("Team handoff · dark") {
    TabNavigationStack {
        TeamHandoffView(
            tab: .search,
            owner: "Search & Discovery",
            brief: "Unified search across users, hashtags, Spaces and captions.",
            entryPoint: "ibugram/Features/Search/SearchPlaceholderView.swift"
        )
    }
    .appContainer(.preview())
    .preferredColorScheme(.dark)
}
