import Foundation

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case feed
    case search
    case create
    case activity
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: "Feed"
        case .search: "Search"
        case .create: "Create"
        case .activity: "Activity"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: "house"
        case .search: "magnifyingglass"
        case .create: "plus.app"
        case .activity: "bell"
        case .profile: "person.crop.circle"
        }
    }
}
