import Foundation

enum SettingsFixtures {
    static let currentSession = DeviceSession(
        id: UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1") ?? UUID(),
        deviceName: "Amina's iPhone",
        userAgent: "IBUgram/1.0 (iPhone; iOS 26.3.1)",
        ipAddress: "10.40.12.8",
        isCurrent: true,
        createdAt: Date(timeIntervalSince1970: 1_758_000_000),
        lastUsedAt: Date(timeIntervalSince1970: 1_779_600_000),
        expiresAt: Date(timeIntervalSince1970: 1_785_000_000)
    )

    static let laptopSession = DeviceSession(
        id: UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2") ?? UUID(),
        deviceName: "MacBook Air",
        userAgent: "Mozilla/5.0",
        ipAddress: "10.40.12.21",
        isCurrent: false,
        createdAt: Date(timeIntervalSince1970: 1_750_000_000),
        lastUsedAt: Date(timeIntervalSince1970: 1_779_000_000),
        expiresAt: Date(timeIntervalSince1970: 1_785_000_000)
    )

    static var stubs: [String: any Sendable] {
        [
            "GET /users/me": ProfileFixtures.currentUser,
            "GET /auth/sessions": [currentSession, laptopSession],
            "GET /users/me/blocked": Page(items: [ProfileFixtures.unfollowedFaculty]),
            "PATCH /users/me": ProfileFixtures.currentUser,
            "POST /users/me/username": ProfileFixtures.currentUser
        ]
    }
}
