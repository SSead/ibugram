import AppIntents
import Foundation

struct PostToIBUgramIntent: AppIntent {
    static var title: LocalizedStringResource { "Post to IBUgram" }
    static var description: IntentDescription {
        IntentDescription("Open the IBUgram composer.")
    }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        ComposerLaunchFlag.request()
        return .result()
    }
}

enum ComposerLaunchFlag {
    static let defaultsKey = "ibugram-intent-open-composer"

    static func request() {
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }

    static func consume() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: defaultsKey) else { return false }
        defaults.set(false, forKey: defaultsKey)
        return true
    }
}
