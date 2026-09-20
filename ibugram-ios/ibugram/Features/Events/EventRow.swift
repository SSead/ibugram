import SwiftUI
import IBUgramKit

struct EventRow: View {
    let event: Event
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(event.title)
                    .font(theme.typography.bodyEmphasis)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(EventScheduleText.range(startsAt: event.startsAt, endsAt: event.endsAt))
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
                HStack(spacing: theme.spacing.xs) {
                    if let place = event.place {
                        Label(place.name, systemImage: "mappin.and.ellipse")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textTertiary)
                            .lineLimit(1)
                    }
                    Text(capacityLabel)
                        .font(theme.typography.caption)
                        .foregroundStyle(event.isFull ? theme.colors.warning : theme.colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing.md)
            .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.md))
            .shadow(theme.shadows.subtle)
            .padding(.horizontal, theme.spacing.screenMargin)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var capacityLabel: String {
        if let capacity = event.capacity {
            if event.isFull {
                return "Full · \(event.counts.going)/\(capacity)"
            }
            return "\(event.counts.going)/\(capacity) going"
        }
        return "\(event.counts.going) going"
    }

    private var accessibilityLabel: String {
        var parts = [event.title, EventScheduleText.range(startsAt: event.startsAt, endsAt: event.endsAt)]
        if let place = event.place { parts.append(place.name) }
        parts.append(capacityLabel)
        return parts.joined(separator: ", ")
    }
}

#Preview("Event row") {
    VStack {
        EventRow(event: EventFixtures.openDay, onOpen: {})
        EventRow(event: EventFixtures.fullLecture, onOpen: {})
    }
    .padding(.vertical)
    .appContainer(.preview())
}
