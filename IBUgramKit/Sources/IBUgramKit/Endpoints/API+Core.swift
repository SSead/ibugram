import Foundation

public enum API {
    /// The contract documents `/health` unprefixed; the server also answers it under
    /// `/api/v1/health` so clients that always prefix keep working.
    public static let health = Endpoint(.get, "/health", isVersioned: false)
    public static let versionedHealth = Endpoint(.get, "/health")
    public static let webSocket = Endpoint(.get, "/ws")

    public enum Auth {
        public static let requestCode = Endpoint(.post, "/auth/request-code")
        public static let verifyCode = Endpoint(.post, "/auth/verify-code")
        public static let refresh = Endpoint(.post, "/auth/refresh")
        public static let logout = Endpoint(.post, "/auth/logout")
        public static let sessions = Endpoint(.get, "/auth/sessions")
        public static let revokeSessionTemplate = Endpoint(.delete, "/auth/sessions/:id")

        public static func revokeSession(id: UUID) -> Endpoint {
            revokeSessionTemplate.substituting(["id": id.uuidString])
        }
    }

    public enum Users {
        public static let me = Endpoint(.get, "/users/me")
        public static let updateMe = Endpoint(.patch, "/users/me")
        public static let setUsername = Endpoint(.post, "/users/me/username")
        public static let suggested = Endpoint(.get, "/users/suggested")
        public static let savedPosts = Endpoint(.get, "/me/saved")

        public static let profileTemplate = Endpoint(.get, "/users/:username")
        public static let profilePostsTemplate = Endpoint(.get, "/users/:username/posts")
        public static let followersTemplate = Endpoint(.get, "/users/:username/followers")
        public static let followingTemplate = Endpoint(.get, "/users/:username/following")
        public static let followTemplate = Endpoint(.post, "/users/:id/follow")
        public static let unfollowTemplate = Endpoint(.delete, "/users/:id/follow")
        public static let blockTemplate = Endpoint(.post, "/users/:id/block")
        public static let unblockTemplate = Endpoint(.delete, "/users/:id/block")

        public static func profile(username: String) -> Endpoint {
            profileTemplate.substituting(["username": username])
        }

        public static func posts(username: String) -> Endpoint {
            profilePostsTemplate.substituting(["username": username])
        }

        public static func followers(username: String) -> Endpoint {
            followersTemplate.substituting(["username": username])
        }

        public static func following(username: String) -> Endpoint {
            followingTemplate.substituting(["username": username])
        }

        public static func follow(id: UUID) -> Endpoint {
            followTemplate.substituting(["id": id.uuidString])
        }

        public static func unfollow(id: UUID) -> Endpoint {
            unfollowTemplate.substituting(["id": id.uuidString])
        }

        public static func block(id: UUID) -> Endpoint {
            blockTemplate.substituting(["id": id.uuidString])
        }

        public static func unblock(id: UUID) -> Endpoint {
            unblockTemplate.substituting(["id": id.uuidString])
        }
    }

    public enum Feed {
        public static let following = Endpoint(.get, "/feed/following")
        public static let discover = Endpoint(.get, "/feed/discover")
    }

    public enum Posts {
        public static let create = Endpoint(.post, "/posts")
        public static let detailTemplate = Endpoint(.get, "/posts/:id")
        public static let updateTemplate = Endpoint(.patch, "/posts/:id")
        public static let deleteTemplate = Endpoint(.delete, "/posts/:id")
        public static let likeTemplate = Endpoint(.post, "/posts/:id/like")
        public static let unlikeTemplate = Endpoint(.delete, "/posts/:id/like")
        public static let saveTemplate = Endpoint(.post, "/posts/:id/save")
        public static let unsaveTemplate = Endpoint(.delete, "/posts/:id/save")
        public static let likesTemplate = Endpoint(.get, "/posts/:id/likes")
        public static let commentsTemplate = Endpoint(.get, "/posts/:id/comments")
        public static let createCommentTemplate = Endpoint(.post, "/posts/:id/comments")

        public static func detail(id: UUID) -> Endpoint { detailTemplate.substituting(["id": id.uuidString]) }
        public static func update(id: UUID) -> Endpoint { updateTemplate.substituting(["id": id.uuidString]) }
        public static func delete(id: UUID) -> Endpoint { deleteTemplate.substituting(["id": id.uuidString]) }
        public static func like(id: UUID) -> Endpoint { likeTemplate.substituting(["id": id.uuidString]) }
        public static func unlike(id: UUID) -> Endpoint { unlikeTemplate.substituting(["id": id.uuidString]) }
        public static func save(id: UUID) -> Endpoint { saveTemplate.substituting(["id": id.uuidString]) }
        public static func unsave(id: UUID) -> Endpoint { unsaveTemplate.substituting(["id": id.uuidString]) }
        public static func likes(id: UUID) -> Endpoint { likesTemplate.substituting(["id": id.uuidString]) }
        public static func comments(id: UUID) -> Endpoint { commentsTemplate.substituting(["id": id.uuidString]) }

        public static func createComment(postId: UUID) -> Endpoint {
            createCommentTemplate.substituting(["id": postId.uuidString])
        }
    }

    public enum Comments {
        public static let deleteTemplate = Endpoint(.delete, "/comments/:id")
        public static let likeTemplate = Endpoint(.post, "/comments/:id/like")
        public static let unlikeTemplate = Endpoint(.delete, "/comments/:id/like")

        public static func delete(id: UUID) -> Endpoint { deleteTemplate.substituting(["id": id.uuidString]) }
        public static func like(id: UUID) -> Endpoint { likeTemplate.substituting(["id": id.uuidString]) }
        public static func unlike(id: UUID) -> Endpoint { unlikeTemplate.substituting(["id": id.uuidString]) }
    }

    public enum MediaRoutes {
        public static let upload = Endpoint(.post, "/media")
        public static let downloadTemplate = Endpoint(.get, "/media/:id")
        public static let thumbnailTemplate = Endpoint(.get, "/media/:id/thumbnail")

        public static func download(id: UUID) -> Endpoint {
            downloadTemplate.substituting(["id": id.uuidString])
        }

        public static func thumbnail(id: UUID) -> Endpoint {
            thumbnailTemplate.substituting(["id": id.uuidString])
        }
    }
}
