import SwiftUI
import IBUgramKit

struct BlockedAccountsView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: BlockedAccountsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Blocked accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? BlockedAccountsViewModel(api: container.api)
            viewModel = model
            await model.load()
        }
    }

    private func content(_ viewModel: BlockedAccountsViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            if viewModel.users.isEmpty {
                EmptyStateView(
                    systemImage: "nosign",
                    title: "No blocked accounts",
                    message: "Accounts you block will appear here. You can unblock them at any time."
                )
            } else {
                List {
                    ForEach(viewModel.users) { user in
                        HStack {
                            FollowListRow(
                                user: user,
                                showsFollowButton: false,
                                onOpen: { router.push(.profile(username: user.username)) },
                                onToggleFollow: {}
                            )
                            Button("Unblock") {
                                Task { await viewModel.unblock(user) }
                            }
                            .font(theme.typography.captionEmphasis)
                            .foregroundStyle(theme.colors.brand)
                            .accessibilityLabel("Unblock \(user.displayName)")
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(theme.colors.background)
                    }
                }
                .listStyle(.plain)
            }
        }
        .errorAlert(bound.presentedError)
    }
}

#Preview("Blocked accounts") {
    TabNavigationStack {
        BlockedAccountsView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview()))
}
