import SwiftUI
import IBUgramKit

struct NewConversationView: View {
    var onOpened: (Conversation) -> Void

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: NewConversationViewModel?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    loaded(viewModel)
                } else {
                    ProgressView()
                }
            }
            .background(theme.colors.background)
            .navigationTitle("New message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel new message")
                }
            }
            .task { await start() }
        }
    }

    private func loaded(_ viewModel: NewConversationViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            searchField(viewModel)
            people(viewModel)
        }
        .errorAlert(bound.presentedError)
        .onChange(of: viewModel.openedConversation) { _, conversation in
            if let conversation { onOpened(conversation) }
        }
    }

    private func searchField(_ viewModel: NewConversationViewModel) -> some View {
        let bound = Bindable(viewModel)
        return HStack(spacing: theme.spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.colors.textTertiary)
            TextField("Search people", text: bound.query)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFocused)
                .accessibilityLabel("Search people")
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }

    @ViewBuilder
    private func people(_ viewModel: NewConversationViewModel) -> some View {
        if viewModel.isIdle {
            suggested(viewModel)
        } else {
            searchResults(viewModel)
        }
    }

    @ViewBuilder
    private func suggested(_ viewModel: NewConversationViewModel) -> some View {
        if viewModel.suggested.isEmpty {
            EmptyStateView(
                systemImage: "person.2",
                title: "Find someone",
                message: "Search for a classmate to start a conversation."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: theme.spacing.xs) {
                    SectionHeader(title: "Suggested")
                    ForEach(viewModel.suggested) { user in
                        FollowListRow(
                            user: user,
                            showsFollowButton: false,
                            onOpen: { Task { await viewModel.openConversation(with: user) } },
                            onToggleFollow: {}
                        )
                    }
                }
                .padding(.vertical, theme.spacing.xs)
            }
        }
    }

    @ViewBuilder
    private func searchResults(_ viewModel: NewConversationViewModel) -> some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .searching:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Searching people")
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.flushPendingSearch() }
        case .results where viewModel.showsEmptyResults:
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No people found",
                message: "Nothing matched “\(viewModel.trimmedQuery)”."
            )
        case .results:
            ScrollView {
                LazyVStack(spacing: theme.spacing.xs) {
                    ForEach(viewModel.people) { user in
                        FollowListRow(
                            user: user,
                            showsFollowButton: false,
                            onOpen: { Task { await viewModel.openConversation(with: user) } },
                            onToggleFollow: {}
                        )
                    }
                }
                .padding(.vertical, theme.spacing.xs)
            }
        }
    }

    private func start() async {
        let userID = session.currentUser?.id ?? SampleData.amina.id
        let model = viewModel ?? NewConversationViewModel(api: container.api, currentUserID: userID)
        viewModel = model
        await model.loadSuggested()
    }
}

#Preview("New message") {
    NewConversationView(onOpened: { _ in })
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs))))
}

#Preview("New message · dark") {
    NewConversationView(onOpened: { _ in })
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
