import SwiftUI
import IBUgramKit

struct EventRSVPBar: View {
    let selected: RSVPStatus
    var isGoingDisabled = false
    var isMutating = false
    var onSelect: (RSVPStatus) -> Void

    @Environment(\.theme) private var theme

    private let options: [RSVPStatus] = [.going, .interested, .none]

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(options, id: \.self) { status in
                Button {
                    onSelect(status)
                } label: {
                    Text(status.title)
                        .font(theme.typography.captionEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.sm)
                        .foregroundStyle(foreground(for: status))
                        .background(background(for: status), in: .rect(cornerRadius: theme.radii.sm))
                }
                .disabled(isMutating || (status == .going && isGoingDisabled && selected != .going))
                .accessibilityLabel(status.title)
                .accessibilityAddTraits(selected == status ? [.isSelected] : [])
            }
        }
        .opacity(isMutating ? 0.7 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("RSVP")
    }

    private func foreground(for status: RSVPStatus) -> Color {
        selected == status ? theme.colors.textOnBrand : theme.colors.brand
    }

    private func background(for status: RSVPStatus) -> Color {
        selected == status ? theme.colors.brand : theme.colors.brandMuted
    }
}

#Preview("RSVP bar") {
    VStack(spacing: 16) {
        EventRSVPBar(selected: .none, onSelect: { _ in })
        EventRSVPBar(selected: .going, onSelect: { _ in })
        EventRSVPBar(selected: .none, isGoingDisabled: true, onSelect: { _ in })
    }
    .padding()
    .appContainer(.preview())
}
