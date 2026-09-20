import SwiftUI
import IBUgramKit

struct EventAttendeeRow: View {
    let attendee: EventAttendee
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.spacing.sm) {
                AvatarView(
                    url: attendee.user.avatarURL,
                    displayName: attendee.user.displayName,
                    size: .medium,
                    showsVerifiedBadge: attendee.user.role == .faculty || attendee.user.isVerified
                )
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    Text(attendee.user.displayName)
                        .font(theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text("@\(attendee.user.username)")
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                TagChip(title: attendee.status.title, style: attendee.status == .going ? .brand : .neutral)
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel("\(attendee.user.displayName), \(attendee.status.title)")
    }
}

#Preview("Attendee row") {
    VStack {
        ForEach(EventFixtures.attendees) { attendee in
            EventAttendeeRow(attendee: attendee, onOpen: {})
        }
    }
    .appContainer(.preview())
}
