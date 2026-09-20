import SwiftUI
import IBUgramKit

struct EventAttendeesView: View {
    let eventID: UUID

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: EventAttendeesViewModel?

    var body: some View {
        Group {
            if let viewModel {
                list(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? EventAttendeesViewModel(api: container.api, eventID: eventID)
            viewModel = model
            await model.load()
        }
    }

    private func list(_ viewModel: EventAttendeesViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.attendees.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.reload() }
            case .loaded where viewModel.attendees.isEmpty:
                EmptyStateView(
                    systemImage: "person.2",
                    title: "No RSVPs yet",
                    message: "People who are going or interested will appear here."
                )
            case .loaded:
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.attendees.items) { attendee in
                        EventAttendeeRow(attendee: attendee) {
                            router.push(.profile(username: attendee.user.username))
                        }
                        .onAppear {
                            if attendee.id == viewModel.attendees.items.last?.id {
                                Task { await viewModel.attendees.loadNextPage() }
                            }
                        }
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }
}

#Preview("Attendees") {
    TabNavigationStack {
        EventAttendeesView(eventID: EventFixtures.openDay.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Attendees · dark") {
    TabNavigationStack {
        EventAttendeesView(eventID: EventFixtures.openDay.id)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
