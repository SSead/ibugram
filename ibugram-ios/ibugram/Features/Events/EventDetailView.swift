import SwiftUI
import IBUgramKit

struct EventDetailView: View {
    let eventID: UUID
    var calendar: any CalendarEventAdding = EventKitCalendarStore()

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: EventDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                loaded(viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel = viewModel ?? EventDetailViewModel(
                api: container.api,
                eventID: eventID,
                calendar: calendar
            )
            await viewModel?.load()
        }
    }

    private func loaded(_ viewModel: EventDetailViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.phase {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }
            case .loaded:
                if let event = viewModel.event {
                    detail(event: event, viewModel: viewModel)
                }
            }
        }
        .navigationTitle(viewModel.event?.title ?? "Event")
        .errorAlert(bound.presentedError)
        .toolbar { calendarButton(viewModel) }
    }

    private func detail(event: Event, viewModel: EventDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                EventHeaderView(event: event)
                EventRSVPBar(
                    selected: viewModel.rsvp,
                    isGoingDisabled: viewModel.isGoingDisabled,
                    isMutating: viewModel.isMutatingRSVP,
                    onSelect: { status in Task { await viewModel.setRSVP(status) } }
                )
                attendeesButton(event)
                relatedLinks(event)
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.md)
        }
        .refreshable { await viewModel.reload() }
    }

    private func attendeesButton(_ event: Event) -> some View {
        Button {
            router.push(.eventAttendees(eventID: event.id))
        } label: {
            HStack {
                Text(attendeeSummary(event))
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.colors.textTertiary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.md))
        }
        .accessibilityLabel(attendeeSummary(event))
        .accessibilityHint("View attendees")
    }

    @ViewBuilder
    private func relatedLinks(_ event: Event) -> some View {
        if let space = event.space {
            Button {
                router.push(.space(slug: space.slug))
            } label: {
                Label(space.name, systemImage: "person.3")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.brand)
            }
            .accessibilityLabel("Open \(space.name)")
        }
        if let postID = event.postId {
            Button {
                router.push(.post(id: postID))
            } label: {
                Label("View post", systemImage: "photo")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.brand)
            }
            .accessibilityLabel("View attached post")
        }
        Button {
            router.push(.profile(username: event.host.username))
        } label: {
            Label("Hosted by \(event.host.displayName)", systemImage: "person")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.brand)
        }
        .accessibilityLabel("Open \(event.host.displayName)")
        Button {
            router.push(.campusMap)
        } label: {
            Label("Show on campus map", systemImage: "map")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.brand)
        }
        .accessibilityLabel("Show on campus map")
    }

    @ToolbarContentBuilder
    private func calendarButton(_ viewModel: EventDetailViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await viewModel.addToCalendar() }
            } label: {
                Image(systemName: viewModel.didAddToCalendar ? "calendar.badge.checkmark" : "calendar.badge.plus")
            }
            .disabled(viewModel.isAddingToCalendar || viewModel.event == nil)
            .accessibilityLabel(viewModel.didAddToCalendar ? "Added to calendar" : "Add to calendar")
        }
    }

    private func attendeeSummary(_ event: Event) -> String {
        "\(event.counts.going) going · \(event.counts.interested) interested"
    }
}

#Preview("Event") {
    TabNavigationStack {
        EventDetailView(eventID: EventFixtures.openDay.id, calendar: PreviewCalendarStore())
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Event · full") {
    TabNavigationStack {
        EventDetailView(eventID: EventFixtures.fullLecture.id, calendar: PreviewCalendarStore())
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Event · error") {
    TabNavigationStack {
        EventDetailView(eventID: EventFixtures.openDay.id, calendar: PreviewCalendarStore())
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Event · dark") {
    TabNavigationStack {
        EventDetailView(eventID: EventFixtures.careerFair.id, calendar: PreviewCalendarStore())
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
