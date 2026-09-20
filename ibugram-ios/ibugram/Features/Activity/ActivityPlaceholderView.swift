import SwiftUI

struct ActivityPlaceholderView: View {
    var body: some View {
        ActivityView()
    }
}

#Preview("Activity tab") {
    TabNavigationStack { ActivityPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ActivityFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Activity tab · dark") {
    TabNavigationStack { ActivityPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: ActivityFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
