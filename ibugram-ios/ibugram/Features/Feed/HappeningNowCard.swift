import SwiftUI

struct HappeningNowCard: View {
    let event: Event

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(event.title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(RelativeTimestamp.abbreviated(from: event.startsAt))
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            if let place = event.place {
                Label(place.name, systemImage: "mappin.and.ellipse")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(theme.spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerRelativeFrame(.horizontal, count: 10, span: 7, spacing: theme.spacing.sm)
        .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.md))
        .shadow(theme.shadows.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [event.title, RelativeTimestamp.abbreviated(from: event.startsAt)]
        if let place = event.place { parts.append(place.name) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Happening now card") {
    HappeningNowCard(event: FeedFixtures.openDay)
        .padding()
        .appContainer(.preview())
}
