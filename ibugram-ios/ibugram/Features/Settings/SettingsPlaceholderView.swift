import SwiftUI
import IBUgramKit

struct SettingsPlaceholderView: View {
    var body: some View {
        SettingsView()
    }
}

#Preview("Settings") {
    TabNavigationStack { SettingsPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Settings · dark") {
    TabNavigationStack { SettingsPlaceholderView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
