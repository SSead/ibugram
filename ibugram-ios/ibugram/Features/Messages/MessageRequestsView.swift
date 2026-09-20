import SwiftUI
import IBUgramKit

struct MessageRequestsView: View {
    var body: some View {
        ConversationListView()
    }
}

#Preview("Message requests route") {
    TabNavigationStack { MessageRequestsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: MessageFixtures.inboxStubs))))
}
