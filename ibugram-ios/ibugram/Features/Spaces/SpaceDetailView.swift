import SwiftUI
import IBUgramKit

struct SpaceDetailView: View {
    let slug: String

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: SpaceDetailViewModel?

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
            viewModel = viewModel ?? SpaceDetailViewModel(api: container.api, slug: slug)
            await viewModel?.load()
        }
    }

    private func loaded(_ viewModel: SpaceDetailViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.phase {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }
            case .loaded:
                if let space = viewModel.space {
                    detailScroll(space: space, viewModel: viewModel)
                }
            }
        }
        .navigationTitle(viewModel.space?.name ?? slug)
        .errorAlert(bound.presentedError)
    }

    private func detailScroll(space: Space, viewModel: SpaceDetailViewModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                SpaceHeaderView(
                    space: space,
                    isMutating: viewModel.isMutatingMembership,
                    onMembers: { router.push(.spaceMembers(slug: space.slug)) },
                    onJoin: { Task { await viewModel.join() } },
                    onLeave: { Task { await viewModel.leave() } }
                )
                PostGridView(
                    posts: viewModel.posts,
                    emptyTitle: "No posts yet",
                    emptyMessage: "When members share to this Space, those photos land here.",
                    onSelect: { router.push(.post(id: $0.id)) }
                )
            }
        }
        .refreshable { await viewModel.reload() }
    }
}

#Preview("Space · public") {
    TabNavigationStack {
        SpaceDetailView(slug: SpaceFixtures.robotics.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.roboticsDetailStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Space · request") {
    TabNavigationStack {
        SpaceDetailView(slug: SpaceFixtures.engineering.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.detailStubs(for: SpaceFixtures.engineering))))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Space · invite") {
    TabNavigationStack {
        SpaceDetailView(slug: SpaceFixtures.facultyCircle.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.detailStubs(for: SpaceFixtures.facultyCircle))))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Space · error") {
    TabNavigationStack {
        SpaceDetailView(slug: "missing")
    }
    .appContainer(.preview(api: MockAPIClient.failing(.notFound)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Space · dark") {
    TabNavigationStack {
        SpaceDetailView(slug: SpaceFixtures.robotics.slug)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.roboticsDetailStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
