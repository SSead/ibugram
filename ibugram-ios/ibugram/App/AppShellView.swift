import SwiftUI
import IBUgramKit

struct AppShellView: View {
    @Environment(\.theme) private var theme
    @Environment(\.appContainer) private var container
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthSessionStore.self) private var session
    @State private var selection: AppTab = .feed
    @State private var lastContentTab: AppTab = .feed
    @State private var isPresentingComposer = false
    @State private var badgeStore = ActivityBadgeStore()

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.feed.title, systemImage: AppTab.feed.systemImage, value: AppTab.feed) {
                TabNavigationStack { FeedView() }
            }
            Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: AppTab.search) {
                TabNavigationStack { SearchView() }
            }
            Tab(AppTab.create.title, systemImage: AppTab.create.systemImage, value: AppTab.create) {
                theme.colors.background.ignoresSafeArea()
            }
            Tab(AppTab.activity.title, systemImage: AppTab.activity.systemImage, value: AppTab.activity) {
                TabNavigationStack { ActivityView(badgeStore: badgeStore) }
            }
            .badge(badgeStore.unreadCount)
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                TabNavigationStack {
                    ProfileView(username: session.currentUser?.username ?? "")
                }
            }
        }
        .tint(theme.colors.brand)
        .onChange(of: selection) { _, current in
            if current == .create {
                let restoreTo = lastContentTab == .create ? AppTab.feed : lastContentTab
                selection = restoreTo
                Task { @MainActor in
                    isPresentingComposer = true
                }
            } else {
                lastContentTab = current
            }
        }
        .sheet(isPresented: $isPresentingComposer) {
            ComposerView()
                .environment(\.appContainer, container)
                .environment(session)
        }
        .overlay { AppLockOverlay() }
        .task {
            presentComposerIfRequested()
            await listenForRealtime()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                presentComposerIfRequested()
            }
        }
    }

    private func presentComposerIfRequested() {
        if LaunchConfiguration.current.openComposer || ComposerLaunchFlag.consume() {
            isPresentingComposer = true
        }
    }

    private func listenForRealtime() async {
        await container.realtime.connect()
        defer { Task { await container.realtime.disconnect() } }
        for await message in await container.realtime.events() {
            switch message {
            case .notificationCreated(let payload):
                badgeStore.applyNotificationCreated(payload.notification)
            case .unreadCountChanged(let payload):
                badgeStore.applyUnreadCountChanged(notifications: payload.notifications)
            default:
                break
            }
        }
    }
}

#Preview("App shell") {
    AppShellView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .environment(AppLockSettingsStore())
}

#Preview("App shell · dark") {
    AppShellView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .environment(AppLockSettingsStore())
        .preferredColorScheme(.dark)
}
