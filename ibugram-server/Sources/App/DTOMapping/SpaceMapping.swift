import Foundation
import IBUgramKit
import Vapor

enum CommunityCursor {
    static func decode(_ raw: String?) throws -> (Date, UUID)? {
        guard let raw, !raw.isEmpty else { return nil }
        let decoded = try KeysetCursor.decode(raw)
        return (decoded.date, decoded.id)
    }
}

enum DeletedAccount {
    static func user() -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            username: "deleted",
            displayName: "Deleted account",
            role: .student,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}

extension SpaceRecord {
    func asSummary(urls: MediaURLBuilder) throws -> SpaceSummary {
        SpaceSummary(
            id: try requireID(),
            slug: slug,
            name: name,
            avatarUrl: $avatarMedia.id.map(urls.url(forMedia:)),
            isOfficial: isOfficial,
            memberCount: memberCount
        )
    }

    func asDTO(membership: SpaceMembership, urls: MediaURLBuilder) throws -> Space {
        let creator: User
        if let createdBy {
            creator = try createdBy.asDTO(urls: urls)
        } else {
            creator = DeletedAccount.user()
        }
        return Space(
            id: try requireID(),
            slug: slug,
            name: name,
            avatarUrl: $avatarMedia.id.map(urls.url(forMedia:)),
            isOfficial: isOfficial,
            memberCount: memberCount,
            bannerUrl: $bannerMedia.id.map(urls.url(forMedia:)),
            description: description,
            kind: kind,
            visibility: visibility,
            viewer: SpaceViewerState(membership: membership),
            createdBy: creator,
            createdAt: createdAt ?? Date()
        )
    }
}

extension SpaceMembershipRecord {
    func asDTO(urls: MediaURLBuilder) throws -> SpaceMember {
        SpaceMember(
            id: try requireID(),
            user: try user.asDTO(urls: urls),
            role: role,
            joinedAt: createdAt ?? Date()
        )
    }
}

enum SpacePostMapper {
    static func dto(
        from post: PostRecord,
        hashtags: [String],
        mentions: [User],
        liked: Bool,
        saved: Bool,
        event: Event?,
        urls: MediaURLBuilder
    ) throws -> Post {
        try post.asDTO(
            author: try post.author.asDTO(urls: urls),
            media: try NestedResourceMapping.media(from: post, urls: urls),
            hashtags: hashtags,
            mentions: mentions,
            space: try post.space.map { try $0.asSummary(urls: urls) },
            event: event,
            location: try post.place.map { try NestedResourceMapping.place($0) },
            viewer: PostViewerState(hasLiked: liked, hasSaved: saved)
        )
    }
}

extension Space: @retroactive AsyncRequestDecodable {}
extension Space: @retroactive AsyncResponseEncodable {}
extension Space: @retroactive Content {}

extension SpaceMember: @retroactive AsyncRequestDecodable {}
extension SpaceMember: @retroactive AsyncResponseEncodable {}
extension SpaceMember: @retroactive Content {}

extension CreateSpaceBody: @retroactive AsyncRequestDecodable {}
extension CreateSpaceBody: @retroactive AsyncResponseEncodable {}
extension CreateSpaceBody: @retroactive Content {}

extension UpdateSpaceBody: @retroactive AsyncRequestDecodable {}
extension UpdateSpaceBody: @retroactive AsyncResponseEncodable {}
extension UpdateSpaceBody: @retroactive Content {}

extension SetSpaceMemberRoleBody: @retroactive AsyncRequestDecodable {}
extension SetSpaceMemberRoleBody: @retroactive AsyncResponseEncodable {}
extension SetSpaceMemberRoleBody: @retroactive Content {}
