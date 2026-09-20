import Foundation
import SwiftUI

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
        didSet { defaults.set(preference.rawValue, forKey: key) }
    }

    var colorScheme: ColorScheme? {
        switch preference {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: key).flatMap(AppearancePreference.init) {
            preference = stored
        } else {
            preference = .system
        }
    }
}
