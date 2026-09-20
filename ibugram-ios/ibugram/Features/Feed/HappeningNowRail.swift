import SwiftUI
import IBUgramKit

struct HappeningNowRail: View {
    let events: [Event]
    var onSelect: (Event) -> Void = { _ in }

    @Environment(\.theme) private var theme

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                SectionHeader(
                    title: "Happening now",
                    subtitle: events.count == 1 ? "1 event on campus" : "\(events.count) events on campus"
                )
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.sm) {
                        ForEach(events) { event in
                            Button {
                                onSelect(event)
                            } label: {
                                HappeningNowCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, theme.spacing.screenMargin)
                    .padding(.bottom, theme.spacing.xs)
                }
                .accessibilityLabel("Happening now")
            }
        }
    }
}

#Preview("Happening now") {
    HappeningNowRail(events: FeedFixtures.happeningNow)
        .appContainer(.preview())
}

#Preview("Happening now · dark") {
    HappeningNowRail(events: FeedFixtures.happeningNow)
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
