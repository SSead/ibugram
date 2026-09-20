import Foundation
import IBUgramKit

enum PostEndpoint {
    struct Create: Endpoint {
        typealias Response = Post

        let payload: CreatePostBody

        var method: HTTPMethod { .post }
        var path: String { "/posts" }
        var body: HTTPBody? { .json(payload) }
    }

    struct Detail: Endpoint {
        typealias Response = Post

        let postID: UUID

        var path: String { "/posts/\(postID)" }
    }

    struct Delete: Endpoint {
        typealias Response = EmptyResponse

        let postID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/posts/\(postID)" }
    }

    struct Like: Endpoint {
        typealias Response = EmptyResponse

        let postID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/posts/\(postID)/like" }
    }

    struct Unlike: Endpoint {
        typealias Response = EmptyResponse

        let postID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/posts/\(postID)/like" }
    }

    struct Save: Endpoint {
        typealias Response = EmptyResponse

        let postID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/posts/\(postID)/save" }
    }

    struct Unsave: Endpoint {
        typealias Response = EmptyResponse

        let postID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/posts/\(postID)/save" }
    }

    struct Likes: Endpoint {
        typealias Response = Paginated<User>

        let postID: UUID
        var cursor: String?
        var limit: Int = 20

        var path: String { "/posts/\(postID)/likes" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct Comments: Endpoint {
        typealias Response = Paginated<Comment>

        let postID: UUID
        var cursor: String?
        var limit: Int = 20

        var path: String { "/posts/\(postID)/comments" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct CreateComment: Endpoint {
        typealias Response = Comment

        let postID: UUID
        let bodyText: String
        let parentID: UUID?

        var method: HTTPMethod { .post }
        var path: String { "/posts/\(postID)/comments" }
        var body: HTTPBody? { .json(Payload(body: bodyText, parentId: parentID)) }

        private struct Payload: Encodable, Sendable {
            let body: String
            let parentId: UUID?
        }
    }

    struct DeleteComment: Endpoint {
        typealias Response = EmptyResponse

        let commentID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/comments/\(commentID)" }
    }

    struct LikeComment: Endpoint {
        typealias Response = EmptyResponse

        let commentID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/comments/\(commentID)/like" }
    }

    struct UnlikeComment: Endpoint {
        typealias Response = EmptyResponse

        let commentID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/comments/\(commentID)/like" }
    }

    static func create(_ payload: CreatePostBody) -> Create { Create(payload: payload) }
    static func detail(postID: UUID) -> Detail { Detail(postID: postID) }
    static func delete(postID: UUID) -> Delete { Delete(postID: postID) }
    static func like(postID: UUID) -> Like { Like(postID: postID) }
    static func unlike(postID: UUID) -> Unlike { Unlike(postID: postID) }
    static func save(postID: UUID) -> Save { Save(postID: postID) }
    static func unsave(postID: UUID) -> Unsave { Unsave(postID: postID) }
    static func likes(postID: UUID, cursor: String? = nil) -> Likes { Likes(postID: postID, cursor: cursor) }
    static func comments(postID: UUID, cursor: String? = nil) -> Comments { Comments(postID: postID, cursor: cursor) }
    static func createComment(postID: UUID, body: String, parentID: UUID? = nil) -> CreateComment {
        CreateComment(postID: postID, bodyText: body, parentID: parentID)
    }
    static func deleteComment(commentID: UUID) -> DeleteComment { DeleteComment(commentID: commentID) }
    static func likeComment(commentID: UUID) -> LikeComment { LikeComment(commentID: commentID) }
    static func unlikeComment(commentID: UUID) -> UnlikeComment { UnlikeComment(commentID: commentID) }
}
