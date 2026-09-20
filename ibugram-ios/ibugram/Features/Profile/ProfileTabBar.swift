import SwiftUI

struct ProfileTabBar: View {
    let tabs: [ProfileContentTab]
    let selection: ProfileContentTab
    var onSelect: (ProfileContentTab) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: theme.spacing.xxs) {
                        Image(systemName: tab.systemImage)
                            .font(theme.typography.headline)
                        Text(tab.title)
                            .font(theme.typography.captionEmphasis)
                    }
                    .foregroundStyle(tab == selection ? theme.colors.brand : theme.colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(tab == selection ? theme.colors.brand : Color.clear)
                            .frame(height: theme.spacing.hairline)
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(tab == selection ? [.isSelected] : [])
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.colors.separator)
                .frame(height: theme.spacing.hairline / 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile content")
    }
}

#Preview("Tabs") {
    ProfileTabBar(tabs: ProfileContentTab.allCases, selection: .posts, onSelect: { _ in })
}
