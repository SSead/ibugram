import Foundation
import IBUgramKit

enum SpaceJoinPolicy {
    static func membership(of space: Space) -> SpaceMembership {
        space.viewer?.membership ?? .none
    }

    static func result(ofJoining visibility: SpaceVisibility) -> SpaceMembership? {
        switch visibility {
        case .public: .member
        case .request: .pending
        case .invite: nil
        }
    }

    static func canJoin(_ space: Space) -> Bool {
        membership(of: space) == .none && result(ofJoining: space.visibility) != nil
    }

    static func canLeave(_ space: Space) -> Bool {
        switch membership(of: space) {
        case .pending, .member, .moderator: true
        case .none, .owner: false
        }
    }

    static func applyingJoin(_ space: Space) -> Space? {
        guard let next = result(ofJoining: space.visibility), canJoin(space) else { return nil }
        return space.applying(membership: next)
    }

    static func applyingLeave(_ space: Space) -> Space? {
        guard canLeave(space) else { return nil }
        return space.applying(membership: .none)
    }
}

extension Space {
    var bannerURL: URL? { RemoteURL.parse(bannerUrl) }
    var avatarResourceURL: URL? { RemoteURL.parse(avatarUrl) }

    func applying(membership: SpaceMembership) -> Space {
        var copy = self
        let previous = viewer?.membership ?? .none
        var count = memberCount
        if previous.countsTowardMembers && !membership.countsTowardMembers {
            count -= 1
        }
        if !previous.countsTowardMembers && membership.countsTowardMembers {
            count += 1
        }
        copy.memberCount = max(0, count)
        copy.viewer = SpaceViewerState(membership: membership)
        return copy
    }
}

extension SpaceMembership {
    var countsTowardMembers: Bool {
        switch self {
        case .member, .moderator, .owner: true
        case .none, .pending: false
        }
    }
}

extension SpaceKind {
    var title: String {
        switch self {
        case .club: "Club"
        case .department: "Department"
        case .course: "Course"
        case .community: "Community"
        }
    }
}

extension SpaceVisibility {
    var title: String {
        switch self {
        case .public: "Public"
        case .request: "Request to join"
        case .invite: "Invite only"
        }
    }
}
