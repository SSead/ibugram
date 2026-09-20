import Foundation

/// Lets UI tests and screenshot runs start the app against fixtures in a chosen auth state.
/// The flags are inert in release builds, so shipping code cannot depend on them.
///
///     xcrun simctl launch <udid> ba.ibu.ibugram -ibugram-mock-api YES -ibugram-auth-state signed-in
struct LaunchConfiguration: Sendable {
    enum ForcedState: String, Sendable {
        case signedOut = "signed-out"
        case onboarding
        case signedIn = "signed-in"
    }

    static let mockAPIKey = "ibugram-mock-api"
    static let authStateKey = "ibugram-auth-state"

    let usesMockAPI: Bool
    let forcedState: ForcedState?

    static let current: LaunchConfiguration = {
        #if DEBUG
        let defaults = UserDefaults.standard
        return LaunchConfiguration(
            usesMockAPI: defaults.bool(forKey: mockAPIKey),
            forcedState: defaults.string(forKey: authStateKey).flatMap(ForcedState.init)
        )
        #else
        return LaunchConfiguration(usesMockAPI: false, forcedState: nil)
        #endif
    }()

    /// Mock runs start with no stored tokens unless `signed-in` was asked for, so
    /// `-ibugram-mock-api YES` on its own lands on the sign-in screen rather than skipping it.
    func makeContainer() -> AppContainer {
        guard usesMockAPI else { return .live() }
        return .preview(tokens: forcedState == .signedIn ? SampleData.tokens : nil)
    }
}
