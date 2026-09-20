import Foundation
import IBUgramKit

enum SpaceFixtures {
    static let robotics = Space(
        id: FeedFixtures.robotics.id,
        slug: FeedFixtures.robotics.slug,
        name: FeedFixtures.robotics.name,
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 186,
        bannerUrl: nil,
        description: "Student robotics club. Builds, competitions, and late-night soldering in A-12.",
        kind: .club,
        visibility: .public,
        viewer: SpaceViewerState(membership: .none),
        createdBy: SampleData.professorKovac,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    static let filmClub = Space(
        id: SearchFixtures.filmClub.id,
        slug: SearchFixtures.filmClub.slug,
        name: SearchFixtures.filmClub.name,
        avatarUrl: nil,
        isOfficial: false,
        memberCount: 31,
        bannerUrl: nil,
        description: "Weekly screenings and a student film night on the lawn.",
        kind: .community,
        visibility: .public,
        viewer: SpaceViewerState(membership: .member),
        createdBy: SampleData.amina,
        createdAt: Date(timeIntervalSince1970: 1_710_000_000)
    )

    static let engineering = Space(
        id: UUID(uuidString: "44444444-4444-4444-8444-444444444445") ?? UUID(),
        slug: "software-engineering",
        name: "Software Engineering",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 412,
        bannerUrl: nil,
        description: "Department Space for SE students and faculty. Request to join.",
        kind: .department,
        visibility: .request,
        viewer: SpaceViewerState(membership: .none),
        createdBy: SampleData.professorKovac,
        createdAt: Date(timeIntervalSince1970: 1_640_000_000)
    )

    static let facultyCircle = Space(
        id: UUID(uuidString: "44444444-4444-4444-8444-444444444446") ?? UUID(),
        slug: "faculty-circle",
        name: "Faculty circle",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 28,
        bannerUrl: nil,
        description: "Invite-only coordination for faculty and staff.",
        kind: .community,
        visibility: .invite,
        viewer: SpaceViewerState(membership: .none),
        createdBy: SampleData.professorKovac,
        createdAt: Date(timeIntervalSince1970: 1_680_000_000)
    )

    static let browse: [Space] = [robotics, filmClub, engineering, facultyCircle]

    static let members: [SpaceMember] = [
        SpaceMember(
            id: UUID(uuidString: "b1111111-1111-4111-8111-111111111111") ?? UUID(),
            user: SampleData.professorKovac,
            role: .owner,
            joinedAt: Date(timeIntervalSince1970: 1_700_000_000)
        ),
        SpaceMember(
            id: UUID(uuidString: "b1111111-1111-4111-8111-111111111112") ?? UUID(),
            user: SampleData.amina,
            role: .member,
            joinedAt: Date(timeIntervalSince1970: 1_720_000_000)
        ),
        SpaceMember(
            id: UUID(uuidString: "b1111111-1111-4111-8111-111111111113") ?? UUID(),
            user: ProfileFixtures.followedStudent,
            role: .moderator,
            joinedAt: Date(timeIntervalSince1970: 1_730_000_000)
        )
    ]

    static let spacePosts: [Post] = [FeedFixtures.carousel, FeedFixtures.liked]

    static var browseStubs: [String: any Sendable] {
        var stubs: [String: any Sendable] = [
            "GET /spaces": Paginated(items: browse),
            "GET /users/me": SampleData.amina
        ]
        for space in browse {
            stubs.merge(detailStubs(for: space)) { _, new in new }
        }
        return stubs
    }

    static var emptyBrowseStubs: [String: any Sendable] {
        ["GET /spaces": Paginated<Space>(items: [])]
    }

    static func detailStubs(for space: Space, posts: [Post] = spacePosts, members: [SpaceMember] = members) -> [String: any Sendable] {
        [
            "GET /spaces/\(space.slug)": space,
            "GET /spaces/\(space.slug)/posts": Paginated(items: posts),
            "GET /spaces/\(space.slug)/members": Paginated(items: members)
        ]
    }

    static var roboticsDetailStubs: [String: any Sendable] { detailStubs(for: robotics) }
}
