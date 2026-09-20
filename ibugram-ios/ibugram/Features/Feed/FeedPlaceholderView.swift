import SwiftUI

struct FeedPlaceholderView: View {
    var body: some View {
        FeedView()
    }
}

#Preview("Feed tab") {
    TabNavigationStack { FeedPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
}

#Preview("Feed tab · dark") {
    TabNavigationStack { FeedPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: FeedFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview(api: MockAPIClient(stubs: FeedFixtures.stubs))))
        .preferredColorScheme(.dark)
}
