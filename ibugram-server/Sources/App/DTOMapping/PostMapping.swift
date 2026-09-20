import Foundation
import IBUgramKit

extension PostRecord {
    func asDTO(
        author: IBUgramKit.User,
        media: [Media],
        hashtags: [String],
        mentions: [IBUgramKit.User],
        space: SpaceSummary?,
        event: Event?,
        location: Place?,
        viewer: PostViewerState?
    ) throws -> Post {
        Post(
            id: try requireID(),
            author: author,
            media: media,
            caption: caption,
            hashtags: hashtags,
            mentions: mentions,
            space: space,
            event: event,
            location: location,
            counts: PostCounts(likes: likeCount, comments: commentCount),
            viewer: viewer,
            commentsEnabled: commentsEnabled,
            createdAt: createdAt ?? Date(),
            editedAt: editedAt
        )
    }

    func carouselMedia(urls: MediaURLBuilder) throws -> [Media] {
        try NestedResourceMapping.media(from: self, urls: urls)
    }
}

enum NestedResourceMapping {
    static func media(from post: PostRecord, urls: MediaURLBuilder) throws -> [Media] {
        try post.attachedMedia
            .sorted { $0.position < $1.position }
            .map { try $0.media.asDTO(urls: urls) }
    }

    static func place(_ place: PlaceRecord) throws -> Place {
        try place.asDTO()
    }
}
