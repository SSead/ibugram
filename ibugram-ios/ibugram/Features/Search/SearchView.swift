import SwiftUI

struct SearchView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: SearchViewModel?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Group {
            if let viewModel {
                loaded(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = viewModel ?? SearchViewModel(api: container.api)
        }
        .task { await viewModel?.loadIdleContent() }
    }

    private func loaded(_ viewModel: SearchViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            searchField(viewModel)
            scopePicker(viewModel)
            bodyContent(viewModel)
        }
        .errorAlert(bound.presentedError)
    }

    private func searchField(_ viewModel: SearchViewModel) -> some View {
        let bound = Bindable(viewModel)
        return HStack(spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.colors.textTertiary)
                TextField("Search people, tags, Spaces", text: bound.query)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit { viewModel.submitCurrentQuery() }
                    .accessibilityLabel("Search")
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))

            if !viewModel.isIdle || isSearchFocused {
                Button("Cancel") {
                    viewModel.cancel()
                    isSearchFocused = false
                }
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.brand)
                .accessibilityLabel("Cancel search")
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }

    private func scopePicker(_ viewModel: SearchViewModel) -> some View {
        Picker("Search scope", selection: Binding(
            get: { viewModel.scope },
            set: { scope in Task { await viewModel.selectScope(scope) } }
        )) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.bottom, theme.spacing.xs)
        .accessibilityLabel("Search scope")
    }

    @ViewBuilder
    private func bodyContent(_ viewModel: SearchViewModel) -> some View {
        if viewModel.isIdle {
            SearchIdleView(
                trending: viewModel.trending,
                suggested: viewModel.suggested,
                recents: viewModel.recents,
                onHashtag: { router.push(.hashtag(tag: $0.tag)) },
                onUser: { router.push(.profile(username: $0.username)) },
                onRecent: { value in Task { await viewModel.applyRecent(value) } }
            )
        } else {
            SearchResultsView(viewModel: viewModel)
        }
    }
}

#Preview("Search idle") {
    TabNavigationStack { SearchView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Search idle · dark") {
    TabNavigationStack { SearchView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
