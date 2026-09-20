import Foundation

enum SampleData {
    static let amina = User(
        id: UUID(uuidString: "11111111-1111-4111-8111-111111111111") ?? UUID(),
        username: "amina.h",
        displayName: "Amina Hodžić",
        avatarUrl: nil,
        bio: "CS senior · building things for campus · IBU Robotics",
        role: .student,
        department: "Information Technologies",
        yearOfStudy: 4,
        isVerified: false,
        counts: UserCounts(posts: 42, followers: 618, following: 214),
        viewer: ViewerRelationship(isFollowing: true, isFollowedBy: true, isBlocked: false),
        createdAt: Date(timeIntervalSince1970: 1_695_000_000)
    )

    static let professorKovac = User(
        id: UUID(uuidString: "22222222-2222-4222-8222-222222222222") ?? UUID(),
        username: "d.kovac",
        displayName: "Prof. Dr. Damir Kovač",
        avatarUrl: nil,
        bio: "Faculty of Engineering and Natural Sciences. Office C-204.",
        role: .faculty,
        department: "Software Engineering",
        yearOfStudy: nil,
        isVerified: true,
        counts: UserCounts(posts: 96, followers: 2_431, following: 87),
        viewer: ViewerRelationship(isFollowing: false, isFollowedBy: false, isBlocked: false),
        createdAt: Date(timeIntervalSince1970: 1_650_000_000)
    )

    static let newcomer = User(
        id: UUID(uuidString: "33333333-3333-4333-8333-333333333333") ?? UUID(),
        username: "",
        displayName: "",
        avatarUrl: nil,
        bio: nil,
        role: .student,
        department: nil,
        yearOfStudy: nil,
        isVerified: false,
        counts: UserCounts(posts: 0, followers: 0, following: 0),
        viewer: nil,
        createdAt: Date(timeIntervalSince1970: 1_758_000_000)
    )

    static let users: [User] = [amina, professorKovac]

    static let tokens = TokenPair(
        accessToken: "preview.access.token",
        refreshToken: "preview.refresh.token",
        accessTokenExpiresAt: Date(timeIntervalSinceNow: 900)
    )

    static let codeChallenge = OneTimeCodeChallenge(
        expiresAt: Date(timeIntervalSinceNow: 600),
        resendAfter: 60,
        debugCode: "482913"
    )

    static let session = AuthSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: 900,
        user: amina,
        needsOnboarding: false
    )

    static let defaultStubs: [String: any Sendable] = [
        "GET /users/me": amina,
        "GET /users/amina.h": amina,
        "GET /users/d.kovac": professorKovac,
        "GET /users/amina.h/followers": Page(items: users, nextCursor: nil),
        "POST /auth/request-code": codeChallenge,
        "POST /auth/verify-code": session,
        "POST /users/me/username": amina,
        "PATCH /users/me": amina
    ]
}