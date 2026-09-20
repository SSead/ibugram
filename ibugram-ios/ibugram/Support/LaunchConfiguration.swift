import Foundation
import IBUgramKit

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
    static let openComposerKey = "ibugram-open-composer"

    let usesMockAPI: Bool
    let forcedState: ForcedState?
    let openComposer: Bool

    static let current: LaunchConfiguration = {
        #if DEBUG
        let defaults = UserDefaults.standard
        return LaunchConfiguration(
            usesMockAPI: defaults.bool(forKey: mockAPIKey),
            forcedState: defaults.string(forKey: authStateKey).flatMap(ForcedState.init),
            openComposer: defaults.bool(forKey: openComposerKey)
        )
        #else
        return LaunchConfiguration(usesMockAPI: false, forcedState: nil, openComposer: false)
        #endif
    }()

    /// Mock runs start with no stored tokens unless `signed-in` was asked for, so
    /// `-ibugram-mock-api YES` on its own lands on the sign-in screen rather than skipping it.
    func makeContainer() -> AppContainer {
        guard usesMockAPI else { return .live() }
        return .preview(
            api: MockAPIClient(stubs: SampleData.previewStubs),
            tokens: forcedState == .signedIn ? SampleData.tokens : nil
        )
    }
}
