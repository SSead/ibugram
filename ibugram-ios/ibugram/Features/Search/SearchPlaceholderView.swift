import SwiftUI
import IBUgramKit

struct SearchPlaceholderView: View {
    var body: some View {
        SearchView()
    }
}

#Preview("Search tab") {
    TabNavigationStack { SearchPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Search tab · dark") {
    TabNavigationStack { SearchPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SearchFixtures.idleStubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
