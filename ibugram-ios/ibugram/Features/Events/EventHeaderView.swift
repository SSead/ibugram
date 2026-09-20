import SwiftUI
import IBUgramKit

struct EventHeaderView: View {
    let event: Event

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(event.title)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)
            Text(EventScheduleText.range(startsAt: event.startsAt, endsAt: event.endsAt))
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
            if let place = event.place {
                Label(place.name, systemImage: "mappin.and.ellipse")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            capacity
            if let description = event.description, !description.isEmpty {
                Text(description)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var capacity: some View {
        Text(capacityLabel)
            .font(theme.typography.subheadline)
            .foregroundStyle(event.isFull ? theme.colors.warning : theme.colors.textSecondary)
    }

    private var capacityLabel: String {
        if let capacity = event.capacity {
            if event.isFull {
                return "Full · \(event.counts.going) of \(capacity) spots"
            }
            return "\(event.counts.going) of \(capacity) going"
        }
        return "\(event.counts.going) going"
    }

    private var accessibilityLabel: String {
        var parts = [event.title, EventScheduleText.range(startsAt: event.startsAt, endsAt: event.endsAt)]
        if let place = event.place { parts.append(place.name) }
        parts.append(capacityLabel)
        if let description = event.description { parts.append(description) }
        return parts.joined(separator: ". ")
    }
}

#Preview("Event header") {
    EventHeaderView(event: EventFixtures.openDay)
        .padding()
        .appContainer(.preview())
}
