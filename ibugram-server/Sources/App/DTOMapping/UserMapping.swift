import Foundation
import IBUgramKit

extension UserRecord {
    /// The contract types `username` and `display_name` as non-optional, but both are
    /// unset until onboarding finishes. Placeholders keep the wire shape intact while
    /// `needs_onboarding` tells the client the values are provisional.
    var effectiveUsername: String {
        if let username { return username }
        let suffix = (id?.uuidString.prefix(8) ?? "00000000").lowercased()
        return Username.reservedPrefix + suffix
    }

    var effectiveDisplayName: String {
        displayName ?? EmailAddress.localPart(of: email) ?? effectiveUsername
    }

    func asDTO(viewer: UserViewerState? = nil, urls: MediaURLBuilder) throws -> IBUgramKit.User {
        IBUgramKit.User(
            id: try requireID(),
            username: effectiveUsername,
            displayName: effectiveDisplayName,
            avatarUrl: $avatarMedia.id.map(urls.url(forMedia:)),
            bio: bio,
            role: role,
            department: department,
            yearOfStudy: yearOfStudy,
            isVerified: isVerified,
            counts: UserCounts(posts: postCount, followers: followerCount, following: followingCount),
            viewer: viewer,
            createdAt: createdAt ?? Date()
        )
    }
}

extension AuthSessionRecord {
    func asDTO(isCurrent: Bool) throws -> IBUgramKit.Session {
        IBUgramKit.Session(
            id: try requireID(),
            deviceName: deviceName,
            userAgent: userAgent,
            ipAddress: ipAddress,
            isCurrent: isCurrent,
            createdAt: createdAt ?? Date(),
            lastUsedAt: lastUsedAt,
            expiresAt: expiresAt
        )
    }
}
