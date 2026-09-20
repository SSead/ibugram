import SwiftUI
import IBUgramKit

struct ActivityView: View {
    var badgeStore: ActivityBadgeStore?

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: ActivityViewModel?

    var body: some View {
        Group {
            if let viewModel {
                loaded(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            attachViewModel()
            await viewModel?.load()
        }
    }

    private func loaded(_ viewModel: ActivityViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.feed.phase {
            case .idle, .loading:
                ActivityLoadingView()
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }
            case .loaded where viewModel.feed.isEmpty:
                EmptyStateView(
                    systemImage: "bell.slash",
                    title: "No activity yet",
                    message: "Likes, comments, follows and mentions will appear here."
                )
            case .loaded:
                RefreshableScrollView(refresh: { await viewModel.reload() }) {
                    ForEach(viewModel.groups) { group in
                        SectionHeader(title: group.period.rawValue)
                        ForEach(group.items) { item in
                            ActivityRow(
                                item: item,
                                isRead: viewModel.isRead(item),
                                displayedActor: item.actors.first.map(viewModel.displayed),
                                onOpen: { open(item) },
                                onFollow: item.kind == .follow
                                    ? { Task { if let actor = item.actors.first { await viewModel.toggleFollow(actor) } } }
                                    : nil
                            )
                            .onAppear {
                                if item.id == viewModel.feed.items.last?.id {
                                    Task { await viewModel.feed.loadNextPage() }
                                }
                            }
                        }
                    }
                }
            }
        }
        .errorAlert(bound.presentedError)
    }

    private func open(_ item: IBUgramKit.Notification) {
        if let post = item.post {
            router.push(.post(id: post.id))
            return
        }
        if let event = item.event {
            router.push(.event(id: event.id))
            return
        }
        if let space = item.space {
            router.push(.space(slug: space.slug))
            return
        }
        if let actor = item.actors.first {
            router.push(.profile(username: actor.username))
        }
    }

    private func attachViewModel() {
        viewModel = viewModel ?? ActivityViewModel(
            api: container.api,
            badge: badgeStore ?? ActivityBadgeStore()
        )
    }
}

private struct ActivityLoadingView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: theme.spacing.sm) {
                    SkeletonView(cornerRadius: theme.radii.pill)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        SkeletonView().frame(height: 12)
                        SkeletonView().frame(width: 120, height: 10)
                    }
                }
                .padding(.horizontal, theme.spacing.screenMargin)
            }
        }
        .padding(.top, theme.spacing.md)
    }
}

#Preview("Activity") {
    TabNavigationStack { ActivityView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ActivityFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Activity · empty") {
    TabNavigationStack { ActivityView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ActivityFixtures.emptyStubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Activity · dark") {
    TabNavigationStack { ActivityView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ActivityFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
