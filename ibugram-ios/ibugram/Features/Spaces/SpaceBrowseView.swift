import SwiftUI
import IBUgramKit

struct SpaceBrowseView: View {
    var currentUser: User?

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @Environment(Router.self) private var router
    @State private var viewModel: SpaceBrowseViewModel?
    @State private var isCreating = false

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
        .navigationTitle("Spaces")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            attachViewModel()
            await viewModel?.load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create a Space")
            }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack {
                CreateSpaceView(currentUser: resolvedUser) { space in
                    isCreating = false
                    router.push(.space(slug: space.slug))
                }
            }
            .environment(\.appContainer, container)
            .environment(session)
        }
    }

    private var resolvedUser: User? { currentUser ?? session.currentUser }

    private func loaded(_ viewModel: SpaceBrowseViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            kindFilter(viewModel)
            list(viewModel)
        }
        .errorAlert(bound.presentedError)
    }

    private func kindFilter(_ viewModel: SpaceBrowseViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                filterChip(title: "All", isSelected: viewModel.selectedKind == nil) {
                    Task { await viewModel.selectKind(nil) }
                }
                ForEach(SpaceKind.allCases, id: \.self) { kind in
                    filterChip(title: kind.title, isSelected: viewModel.selectedKind == kind) {
                        Task { await viewModel.selectKind(kind) }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel("Space kind")
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            TagChip(title: title, style: isSelected ? .brand : .neutral, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private func list(_ viewModel: SpaceBrowseViewModel) -> some View {
        switch viewModel.spaces.phase {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.reload() }
        case .loaded where viewModel.spaces.isEmpty:
            EmptyStateView(
                systemImage: "person.3",
                title: "No Spaces yet",
                message: "Clubs, departments and courses will appear here. Create one for your campus group.",
                actionTitle: "Create a Space",
                action: { isCreating = true }
            )
        case .loaded:
            RefreshableScrollView(refresh: { await viewModel.reload() }) {
                ForEach(viewModel.spaces.items) { space in
                    SpaceRow(space: space) {
                        router.push(.space(slug: space.slug))
                    }
                    .onAppear {
                        if space.id == viewModel.spaces.items.last?.id {
                            Task { await viewModel.spaces.loadNextPage() }
                        }
                    }
                }
            }
        }
    }

    private func attachViewModel() {
        viewModel = viewModel ?? SpaceBrowseViewModel(api: container.api)
    }
}

#Preview("Spaces") {
    TabNavigationStack {
        SpaceBrowseView(currentUser: SampleData.amina)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.browseStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Spaces · empty") {
    TabNavigationStack {
        SpaceBrowseView(currentUser: SampleData.amina)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.emptyBrowseStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Spaces · error") {
    TabNavigationStack {
        SpaceBrowseView(currentUser: SampleData.amina)
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Spaces · dark") {
    TabNavigationStack {
        SpaceBrowseView(currentUser: SampleData.amina)
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.browseStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
