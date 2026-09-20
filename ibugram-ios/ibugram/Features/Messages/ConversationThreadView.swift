import SwiftUI
import IBUgramKit

struct ConversationThreadView: View {
    let conversationID: UUID
    var initialConversation: Conversation?

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: ConversationThreadViewModel?

    var body: some View {
        Group {
            if let viewModel {
                loaded(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await start() }
    }

    private func loaded(_ viewModel: ConversationThreadViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: 0) {
            threadBody(viewModel)
            if viewModel.isRequest {
                MessageRequestBanner(
                    senderName: viewModel.title,
                    isAccepting: viewModel.isAccepting,
                    onAccept: { Task { await viewModel.acceptRequest() } }
                )
            }
            if let typing = viewModel.typingLabel {
                TypingIndicatorView(label: typing)
            }
            MessageComposerBar(
                text: bound.draft,
                isSending: viewModel.isSending,
                onSend: { Task { await viewModel.sendDraft() } },
                onPickImage: { data in Task { await viewModel.sendImage(jpeg: data) } }
            )
            .onChange(of: viewModel.draft) { _, newValue in
                Task { await viewModel.draftDidChange(newValue) }
            }
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            if let subtitle = viewModel.peerPresenceLabel {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(viewModel.title)
                            .font(theme.typography.bodyEmphasis)
                        Text(subtitle)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .errorAlert(bound.presentedError)
    }

    @ViewBuilder
    private func threadBody(_ viewModel: ConversationThreadViewModel) -> some View {
        if viewModel.isInitialLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading conversation")
        } else if case .failed(let error) = viewModel.phase, viewModel.messages.isEmpty {
            ErrorStateView(error: error, retry: { await viewModel.load() })
        } else if viewModel.isEmpty {
            EmptyStateView(
                systemImage: "bubble.left",
                title: "No messages yet",
                message: "Say hello. This is the start of the conversation."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            messageList(viewModel)
        }
    }

    private func messageList(_ viewModel: ConversationThreadViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.xs) {
                if viewModel.isLoadingOlder {
                    ProgressView()
                        .padding(theme.spacing.sm)
                        .accessibilityLabel("Loading earlier messages")
                }
                ForEach(viewModel.chronological) { message in
                    MessageBubble(
                        message: message,
                        isFromCurrentUser: viewModel.isFromCurrentUser(message)
                    )
                    .onAppear {
                        if message.id == viewModel.chronological.first?.id {
                            Task { await viewModel.loadOlderMessages() }
                        }
                    }
                }
            }
            .padding(.vertical, theme.spacing.sm)
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
    }

    private func start() async {
        let user = session.currentUser ?? SampleData.amina
        let model = viewModel ?? ConversationThreadViewModel(
            api: container.api,
            realtime: container.realtime,
            conversationID: conversationID,
            currentUser: user,
            conversation: initialConversation
        )
        viewModel = model
        await model.load()
        await model.listenForRealtime()
    }
}

#Preview("Thread") {
    TabNavigationStack {
        ConversationThreadView(
            conversationID: MessageFixtures.inboxID,
            initialConversation: MessageFixtures.inboxConversation
        )
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.threadStubs)))
    .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.threadStubs))))
}

#Preview("Thread · empty") {
    TabNavigationStack {
        ConversationThreadView(
            conversationID: MessageFixtures.emptyThreadID,
            initialConversation: MessageFixtures.emptyConversation
        )
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.threadStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Thread · offline") {
    TabNavigationStack {
        ConversationThreadView(conversationID: MessageFixtures.inboxID)
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Thread · loading") {
    TabNavigationStack {
        ConversationThreadView(conversationID: MessageFixtures.inboxID)
    }
    .appContainer(.preview(api: MockAPIClient.loadingForever()))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Thread · request") {
    TabNavigationStack {
        ConversationThreadView(
            conversationID: MessageFixtures.requestID,
            initialConversation: MessageFixtures.requestConversation
        )
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.requestStubs)))
    .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.requestStubs))))
}

#Preview("Thread · dark") {
    TabNavigationStack {
        ConversationThreadView(
            conversationID: MessageFixtures.inboxID,
            initialConversation: MessageFixtures.inboxConversation
        )
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.threadStubs)))
    .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.threadStubs))))
    .preferredColorScheme(.dark)
}
