import SwiftUI
import IBUgramKit

struct FollowListView: View {
    let username: String
    let kind: FollowListViewModel.Kind
    var currentUserID: UUID?

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @Environment(Router.self) private var router
    @State private var viewModel: FollowListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                list(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            attachViewModel()
            await viewModel?.load()
        }
    }

    private func list(_ viewModel: FollowListViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.people.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.reload() }
            case .loaded where viewModel.people.isEmpty:
                EmptyStateView(
                    systemImage: "person.2",
                    title: "Nobody here yet",
                    message: kind == .followers
                        ? "When people follow this account they will appear here."
                        : "Accounts this person follows will appear here."
                )
            case .loaded:
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.people.items) { user in
                        FollowListRow(
                            user: displayed(user, viewModel: viewModel),
                            showsFollowButton: !viewModel.isCurrentUser(user),
                            onOpen: { router.push(.profile(username: user.username)) },
                            onToggleFollow: { Task { await viewModel.toggleFollow(user) } }
                        )
                        .onAppear {
                            if user.id == viewModel.people.items.last?.id {
                                Task { await viewModel.people.loadNextPage() }
                            }
                        }
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }

    private func displayed(_ user: User, viewModel: FollowListViewModel) -> User {
        user.withFollowState(isFollowing: viewModel.isFollowing(user))
    }

    private func attachViewModel() {
        viewModel = viewModel ?? FollowListViewModel(
            api: container.api,
            username: username,
            kind: kind,
            currentUserID: currentUserID ?? session.currentUser?.id
        )
    }
}

#Preview("Followers") {
    TabNavigationStack {
        FollowListView(
            username: ProfileFixtures.currentUser.username,
            kind: .followers,
            currentUserID: ProfileFixtures.currentUser.id
        )
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
    .environment(AuthSessionStore(container: .preview()))
}
