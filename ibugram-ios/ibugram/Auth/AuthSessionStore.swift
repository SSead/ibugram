import Foundation

@MainActor
@Observable
final class AuthSessionStore {
    enum State: Sendable, Equatable {
        case loading
        case signedOut
        case onboarding(User)
        case signedIn(User)
    }

    private(set) var state: State = .loading

    private let container: AppContainer
    private var invalidationWatcher: Task<Void, Never>?

    init(container: AppContainer) {
        self.container = container
        watchForSessionInvalidation()
    }

    var currentUser: User? {
        switch state {
        case .onboarding(let user), .signedIn(let user): user
        case .loading, .signedOut: nil
        }
    }

    func restore() async {
        if let forced = LaunchConfiguration.current.forcedState {
            state = Self.state(for: forced)
            return
        }
        guard await container.tokenStore.currentTokens() != nil else {
            state = .signedOut
            return
        }
        do {
            let user = try await container.api.send(UserEndpoint.me())
            state = user.needsProfileSetup ? .onboarding(user) : .signedIn(user)
            await container.realtime.connect()
        } catch {
            state = .signedOut
        }
    }

    func begin(_ session: AuthSession) async {
        try? await container.tokenStore.save(TokenPair(session: session))
        state = session.needsOnboarding ? .onboarding(session.user) : .signedIn(session.user)
        await container.realtime.connect()
    }

    func completeOnboarding(with user: User) {
        state = .signedIn(user)
    }

    func update(user: User) {
        switch state {
        case .onboarding: state = .onboarding(user)
        case .signedIn: state = .signedIn(user)
        case .loading, .signedOut: break
        }
    }

    func signOut() async {
        if let tokens = await container.tokenStore.currentTokens() {
            _ = try? await container.api.send(AuthEndpoint.logout(refreshToken: tokens.refreshToken))
        }
        try? await container.tokenStore.clear()
        await container.realtime.disconnect()
        await container.cache.removeAll()
        state = .signedOut
    }

    private static func state(for forced: LaunchConfiguration.ForcedState) -> State {
        switch forced {
        case .signedOut: .signedOut
        case .onboarding: .onboarding(SampleData.newcomer)
        case .signedIn: .signedIn(SampleData.amina)
        }
    }

    private func watchForSessionInvalidation() {
        invalidationWatcher = Task { [weak self, events = container.sessionInvalidation.events] in
            for await _ in events {
                guard let self else { return }
                await self.container.realtime.disconnect()
                self.state = .signedOut
            }
        }
    }
}

private extension User {
    var needsProfileSetup: Bool {
        username.isEmpty || displayName.isEmpty
    }
}
