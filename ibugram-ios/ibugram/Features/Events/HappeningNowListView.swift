import SwiftUI
import IBUgramKit

struct HappeningNowListView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: HappeningNowListViewModel?

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
        .navigationTitle("Happening now")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? HappeningNowListViewModel(api: container.api)
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

    private func loaded(_ viewModel: HappeningNowListViewModel) -> some View {
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
                    systemImage: "sparkles",
                    title: "Nothing happening right now",
                    message: "Check upcoming events, or pull to refresh when campus wakes up."
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

#Preview("Happening now") {
    TabNavigationStack {
        HappeningNowListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Happening now · empty") {
    TabNavigationStack {
        HappeningNowListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.emptyListStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Happening now · dark") {
    TabNavigationStack {
        HappeningNowListView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: EventFixtures.listStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
