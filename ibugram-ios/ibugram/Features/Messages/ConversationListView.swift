import SwiftUI
import IBUgramKit

struct ConversationListView: View {
    var initialFilter: ConversationFilter = .inbox

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: ConversationListViewModel?
    @State private var isPresentingNewMessage = false

    var body: some View {
        Group {
            if let viewModel {
                loaded(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { composeButton }
        .sheet(isPresented: $isPresentingNewMessage) { newMessageSheet }
        .task { await start() }
    }

    private func loaded(_ viewModel: ConversationListViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            filterPicker(viewModel)
            mailbox(viewModel)
        }
        .errorAlert(bound.presentedError)
    }

    private func filterPicker(_ viewModel: ConversationListViewModel) -> some View {
        Picker("Mailbox", selection: Binding(
            get: { viewModel.selectedFilter },
            set: { filter in Task { await viewModel.selectFilter(filter) } }
        )) {
            Text("Inbox").tag(ConversationFilter.inbox)
            Text("Requests").tag(ConversationFilter.requests)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
        .accessibilityLabel("Mailbox")
        .tint(theme.colors.brand)
    }

    @ViewBuilder
    private func mailbox(_ viewModel: ConversationListViewModel) -> some View {
        if viewModel.isInitialLoading {
            ConversationListLoadingView()
        } else if viewModel.isEmpty {
            EmptyStateView(
                systemImage: viewModel.selectedFilter == .inbox ? "bubble.left.and.bubble.right" : "tray",
                title: viewModel.selectedFilter == .inbox ? "No messages yet" : "No requests",
                message: viewModel.selectedFilter == .inbox
                    ? "Start a conversation with someone on campus."
                    : "Message requests from people you do not follow will land here.",
                actionTitle: viewModel.selectedFilter == .inbox ? "New message" : nil,
                action: viewModel.selectedFilter == .inbox ? { isPresentingNewMessage = true } : nil
            )
        } else if case .failed(let error) = viewModel.phase, viewModel.conversations.isEmpty {
            ErrorStateView(error: error, retry: { await viewModel.reload() })
        } else {
            conversationList(viewModel)
        }
    }

    private func conversationList(_ viewModel: ConversationListViewModel) -> some View {
        RefreshableScrollView(refresh: { await viewModel.reload() }) {
            ForEach(viewModel.conversations) { conversation in
                ConversationRow(
                    conversation: conversation,
                    title: viewModel.title(for: conversation),
                    currentUserID: viewModel.currentUserID,
                    isOnline: viewModel.isOnline(in: conversation),
                    onOpen: { router.push(.conversation(id: conversation.id)) },
                    onAccept: conversation.isRequest
                        ? { Task { await viewModel.accept(conversation) } }
                        : nil
                )
                .onAppear {
                    if conversation.id == viewModel.conversations.last?.id {
                        Task { await viewModel.loadNextPage() }
                    }
                }
            }
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(theme.spacing.md)
                    .accessibilityLabel("Loading more conversations")
            }
        }
    }

    @ToolbarContentBuilder
    private var composeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresentingNewMessage = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("New message")
        }
    }

    private var newMessageSheet: some View {
        NewConversationView { conversation in
            isPresentingNewMessage = false
            router.push(.conversation(id: conversation.id))
        }
        .environment(\.appContainer, container)
        .environment(session)
    }

    private func start() async {
        let userID = session.currentUser?.id ?? SampleData.amina.id
        let model = viewModel ?? ConversationListViewModel(
            api: container.api,
            realtime: container.realtime,
            currentUserID: userID,
            filter: initialFilter
        )
        viewModel = model
        await model.load()
        await model.listenForRealtime()
    }
}

private struct ConversationListLoadingView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: theme.spacing.sm) {
                    SkeletonView(cornerRadius: theme.radii.pill)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        SkeletonView().frame(height: 12)
                        SkeletonView().frame(width: 180, height: 10)
                    }
                }
                .padding(.horizontal, theme.spacing.screenMargin)
            }
        }
        .padding(.top, theme.spacing.md)
    }
}

#Preview("Inbox") {
    TabNavigationStack { ConversationListView() }
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs))))
}

#Preview("Inbox · empty") {
    TabNavigationStack { ConversationListView() }
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.emptyStubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Inbox · offline") {
    TabNavigationStack { ConversationListView() }
        .appContainer(.preview(api: MockAPIClient.failing(.offline)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Inbox · loading") {
    TabNavigationStack { ConversationListView() }
        .appContainer(.preview(api: MockAPIClient.loadingForever()))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Requests") {
    TabNavigationStack { ConversationListView(initialFilter: .requests) }
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.requestStubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.requestStubs))))
}

#Preview("Inbox · dark") {
    TabNavigationStack { ConversationListView() }
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs))))
        .preferredColorScheme(.dark)
}
