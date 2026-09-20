import Foundation

enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

@MainActor
@Observable
final class AppearanceSettingsStore {
    private let key = "ibugram.appearance"
    private let defaults: UserDefaults

    var preference: AppearancePreference {
        didSet {
            defaults.set(preference.rawValue, forKey: key)
            applyToOpenWindows()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: key).flatMap(AppearancePreference.init) {
            preference = stored
        } else {
            preference = .system
        }
        applyToOpenWindows()
    }

    /// Apply at the window so appearance works without editing `AppShellView`.
    func applyToOpenWindows() {
        #if canImport(UIKit)
        applyUserInterfaceStyle()
        #endif
    }
}

#if canImport(UIKit)
import UIKit

private extension AppearanceSettingsStore {
    func applyUserInterfaceStyle() {
        let style: UIUserInterfaceStyle = switch preference {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
#endif
