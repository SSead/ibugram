import SwiftUI

struct RootView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @State private var session: AuthSessionStore?

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            if let session {
                content(for: session)
                    .environment(session)
            } else {
                LaunchView()
            }
        }
        .task { await startSessionIfNeeded() }
    }

    @ViewBuilder
    private func content(for session: AuthSessionStore) -> some View {
        switch session.state {
        case .loading:
            LaunchView()
        case .signedOut:
            SignInView()
        case .onboarding(let user):
            OnboardingFlowView(user: user)
        case .signedIn:
            AppShellView()
        }
    }

    private func startSessionIfNeeded() async {
        guard session == nil else { return }
        let store = AuthSessionStore(container: container)
        session = store
        await store.restore()
    }
}

#Preview("Signed out") {
    RootView()
        .appContainer(.preview())
}

#Preview("Signed out · dark") {
    RootView()
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
