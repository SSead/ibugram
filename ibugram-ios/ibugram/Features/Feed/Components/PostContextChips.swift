import SwiftUI
import IBUgramKit

struct PostContextChips: View {
    let post: Post
    var onSpace: (SpaceSummary) -> Void = { _ in }
    var onEvent: (Event) -> Void = { _ in }
    var onLocation: (Place) -> Void = { _ in }

    @Environment(\.theme) private var theme

    var body: some View {
        if hasChips {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    if let space = post.space {
                        Button {
                            onSpace(space)
                        } label: {
                            TagChip(
                                title: space.name,
                                icon: space.isOfficial ? "checkmark.seal.fill" : "person.3.fill",
                                style: .brand
                            )
                            .accessibilityHidden(true)
                        }
                        .accessibilityLabel("Space, \(space.name)")
                    }
                    if let event = post.event {
                        Button {
                            onEvent(event)
                        } label: {
                            TagChip(title: event.title, icon: "calendar", style: .accent)
                                .accessibilityHidden(true)
                        }
                        .accessibilityLabel("Event, \(event.title)")
                    }
                    if let location = post.location {
                        Button {
                            onLocation(location)
                        } label: {
                            TagChip(title: location.name, icon: "mappin.and.ellipse", style: .neutral)
                                .accessibilityHidden(true)
                        }
                        .accessibilityLabel("Location, \(location.name)")
                    }
                }
                .padding(.horizontal, theme.spacing.screenMargin)
            }
            .padding(.bottom, theme.spacing.xs)
        }
    }

    private var hasChips: Bool {
        post.space != nil || post.event != nil || post.location != nil
    }
}

#Preview("Context chips") {
    VStack(alignment: .leading, spacing: 16) {
        PostContextChips(post: FeedFixtures.liked)
        PostContextChips(post: FeedFixtures.singleImage)
        PostContextChips(post: FeedFixtures.facultyAuthor)
        PostContextChips(post: FeedFixtures.carousel)
    }
    .padding(.vertical)
    .appContainer(.preview())
}

#Preview("Context chips · dark") {
    PostContextChips(post: FeedFixtures.liked)
        .padding(.vertical)
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
