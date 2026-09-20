import SwiftUI
import IBUgramKit

struct SpaceMembersView: View {
    let slug: String

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: SpaceMembersViewModel?

    var body: some View {
        Group {
            if let viewModel {
                list(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? SpaceMembersViewModel(api: container.api, slug: slug)
            viewModel = model
            await model.load()
        }
    }

    private func list(_ viewModel: SpaceMembersViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.members.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.reload() }
            case .loaded where viewModel.members.isEmpty:
                EmptyStateView(
                    systemImage: "person.2",
                    title: "No members yet",
                    message: "People who join this Space will appear here."
                )
            case .loaded:
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.members.items) { member in
                        SpaceMemberRow(member: member) {
                            router.push(.profile(username: member.user.username))
                        }
                        .onAppear {
                            if member.id == viewModel.members.items.last?.id {
                                Task { await viewModel.members.loadNextPage() }
                            }
                        }
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }
}

#Preview("Members") {
    TabNavigationStack {
        SpaceMembersView(slug: SpaceFixtures.robotics.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.roboticsDetailStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Members · dark") {
    TabNavigationStack {
        SpaceMembersView(slug: SpaceFixtures.robotics.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.roboticsDetailStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
