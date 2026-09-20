import SwiftUI

struct AppShellView: View {
    @Environment(\.theme) private var theme
    @State private var selection: AppTab = .feed
    @State private var isPresentingComposer = false

    var body: some View {
        TabView(selection: tabSelection) {
            Tab(AppTab.feed.title, systemImage: AppTab.feed.systemImage, value: AppTab.feed) {
                TabNavigationStack { FeedPlaceholderView() }
            }
            Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: AppTab.search) {
                TabNavigationStack { SearchPlaceholderView() }
            }
            Tab(AppTab.create.title, systemImage: AppTab.create.systemImage, value: AppTab.create) {
                Color.clear
            }
            Tab(AppTab.activity.title, systemImage: AppTab.activity.systemImage, value: AppTab.activity) {
                TabNavigationStack { ActivityPlaceholderView() }
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                TabNavigationStack { ProfilePlaceholderView() }
            }
        }
        .tint(theme.colors.brand)
        .sheet(isPresented: $isPresentingComposer) {
            ComposerPlaceholderView()
        }
    }

    /// The Create tab is a button, not a destination: selecting it presents the composer modally
    /// and leaves the previously selected tab in place.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { newValue in
                guard newValue == .create else {
                    selection = newValue
                    return
                }
                isPresentingComposer = true
            }
        )
    }
}

#Preview("App shell") {
    AppShellView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("App shell · dark") {
    AppShellView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
