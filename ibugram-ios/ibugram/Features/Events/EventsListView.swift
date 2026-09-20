import SwiftUI
import IBUgramKit

struct EventsListView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: EventsListViewModel?

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
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? EventsListViewModel(api: container.api)
            viewModel = model
            await model.load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.campusMap)
                } label: {
                    Image(systemName: "map")
                }
                .accessibilityLabel("Campus map")
            }
        }
    }

    private func loaded(_ viewModel: EventsListViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.events.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.reload() }
            case .loaded where viewModel.events.isEmpty:
                EmptyStateView(
                    systemImage: "calendar",
                    title: "No upcoming events",
                    message: "When faculty publish campus events they will appear here."
                )
            case .loaded:
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.events.items) { event in
                        EventRow(event: event) {
                            router.push(.event(id: event.id))
                        }
                        .onAppear {
                            if event.id == viewModel.events.items.last?.id {
                                Task { await viewModel.events.loadNextPage() }
                            }
                        }
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }
}

#Preview("Events") {
    TabNavigationStack {
        EventsListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Events · empty") {
    TabNavigationStack {
        EventsListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.emptyListStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Events · error") {
    TabNavigationStack {
        EventsListView()
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Events · dark") {
    TabNavigationStack {
        EventsListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
