import SwiftUI

struct ProfileView: View {
    let username: String
    var previewCurrentUser: User?

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @Environment(Router.self) private var router
    @State private var viewModel: ProfileViewModel?
    @State private var isEditing = false
    @State private var reportReason: ReportReason?
    @State private var confirmBlock = false

    var body: some View {
        content
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { attachViewModel() }
            .task { await viewModel?.load() }
            .sheet(isPresented: $isEditing) { editSheet }
            .confirmationDialog("Block this account?", isPresented: $confirmBlock, titleVisibility: .visible) {
                Button(blockActionTitle, role: .destructive) {
                    Task { await viewModel?.toggleBlock() }
                }
            } message: {
                Text("They will not be able to see your profile or posts.")
            }
            .confirmationDialog("Report this account", isPresented: Binding(
                get: { reportReason != nil },
                set: { if !$0 { reportReason = nil } }
            ), titleVisibility: .visible) {
                ForEach(ReportReason.allCases) { reason in
                    Button(reason.title) {
                        Task { await viewModel?.report(reason: reason) }
                        reportReason = nil
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            loadedContent(viewModel)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadedContent(_ viewModel: ProfileViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.phase {
            case .loading:
                ProfileLoadingView()
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }
            case .loaded:
                if let user = viewModel.user {
                    profileScroll(user: user, viewModel: viewModel)
                }
            }
        }
        .navigationTitle(viewModel.user.map { "@\($0.username)" } ?? username)
        .toolbar { toolbar(viewModel) }
        .errorAlert(bound.presentedError)
        .refreshable { await viewModel.reload() }
    }

    private func profileScroll(user: User, viewModel: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeaderView(
                    user: user,
                    isOwnProfile: viewModel.isOwnProfile,
                    onFollowers: { router.push(.followers(username: user.username)) },
                    onFollowing: { router.push(.following(username: user.username)) },
                    onPosts: { Task { await viewModel.selectTab(.posts) } },
                    onEditProfile: { isEditing = true },
                    onToggleFollow: { Task { await viewModel.toggleFollow() } }
                )
                ProfileTabBar(tabs: viewModel.visibleTabs, selection: viewModel.selectedTab) { tab in
                    Task { await viewModel.selectTab(tab) }
                }
                .padding(.top, theme.spacing.md)
                PostGridView(
                    posts: viewModel.grid(for: viewModel.selectedTab),
                    emptyTitle: emptyTitle(for: viewModel.selectedTab),
                    emptyMessage: emptyMessage(for: viewModel.selectedTab, isOwn: viewModel.isOwnProfile),
                    onSelect: { router.push(.post(id: $0.id)) }
                )
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbar(_ viewModel: ProfileViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isOwnProfile {
                Button {
                    router.push(.settings)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            } else {
                Menu {
                    Button(blockActionTitle, role: .destructive) { confirmBlock = true }
                    Button("Report", role: .destructive) { reportReason = .other }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More actions")
            }
        }
    }

    private var blockActionTitle: String {
        viewModel?.user?.viewer?.isBlocked == true ? "Unblock" : "Block"
    }

    @ViewBuilder
    private var editSheet: some View {
        if let user = viewModel?.user ?? session.currentUser {
            NavigationStack {
                EditProfileView(user: user) { updated in
                    viewModel?.applyEditedProfile(updated)
                    session.update(user: updated)
                    isEditing = false
                }
            }
        }
    }

    private func attachViewModel() {
        viewModel = viewModel ?? ProfileViewModel(
            api: container.api,
            username: username,
            currentUser: previewCurrentUser ?? session.currentUser
        )
    }

    private func emptyTitle(for tab: ProfileContentTab) -> String {
        switch tab {
        case .posts: "No posts yet"
        case .saved: "No saved posts"
        case .tagged: "No tagged posts"
        }
    }

    private func emptyMessage(for tab: ProfileContentTab, isOwn: Bool) -> String {
        switch tab {
        case .posts:
            isOwn ? "When you share a photo it will show up here." : "This person has not posted yet."
        case .saved:
            "Posts you save will live here, just on this device’s account."
        case .tagged:
            isOwn ? "When someone tags you, those posts will appear here." : "This person has not been tagged yet."
        }
    }
}

private struct ProfileLoadingView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.md) {
                    SkeletonView(cornerRadius: theme.radii.pill)
                        .frame(width: 112, height: 112)
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        SkeletonView().frame(width: 160, height: 16)
                        SkeletonView().frame(width: 100, height: 12)
                        SkeletonView().frame(width: 180, height: 12)
                    }
                }
                .padding(.horizontal, theme.spacing.screenMargin)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.hairline), count: 3),
                    spacing: theme.spacing.hairline
                ) {
                    ForEach(0..<9, id: \.self) { _ in
                        SkeletonView(cornerRadius: 0)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.top, theme.spacing.md)
        }
    }
}

#Preview("Own profile") {
    TabNavigationStack {
        ProfileView(username: ProfileFixtures.currentUser.username, previewCurrentUser: ProfileFixtures.currentUser)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Followed user") {
    TabNavigationStack {
        ProfileView(username: ProfileFixtures.followedStudent.username, previewCurrentUser: ProfileFixtures.currentUser)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.followedUserStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Unfollowed faculty") {
    TabNavigationStack {
        ProfileView(username: ProfileFixtures.unfollowedFaculty.username, previewCurrentUser: ProfileFixtures.currentUser)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.unfollowedFacultyStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Empty grid") {
    TabNavigationStack {
        ProfileView(username: ProfileFixtures.currentUser.username, previewCurrentUser: ProfileFixtures.currentUser)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.emptyGridStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Own profile · dark") {
    TabNavigationStack {
        ProfileView(username: ProfileFixtures.currentUser.username, previewCurrentUser: ProfileFixtures.currentUser)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
