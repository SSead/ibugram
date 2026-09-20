import Foundation

enum UserEndpoint {
    struct Me: Endpoint {
        typealias Response = User

        var path: String { "/users/me" }
    }

    struct UpdateProfile: Endpoint {
        typealias Response = User

        var displayName: String?
        var bio: String?
        var department: String?
        var yearOfStudy: Int?
        var avatarMediaId: UUID?

        var method: HTTPMethod { .patch }
        var path: String { "/users/me" }
        var body: HTTPBody? {
            .json(
                Payload(
                    displayName: displayName,
                    bio: bio,
                    department: department,
                    yearOfStudy: yearOfStudy,
                    avatarMediaId: avatarMediaId
                )
            )
        }

        private struct Payload: Encodable, Sendable {
            let displayName: String?
            let bio: String?
            let department: String?
            let yearOfStudy: Int?
            let avatarMediaId: UUID?
        }
    }

    struct ClaimUsername: Endpoint {
        typealias Response = User

        let username: String

        var method: HTTPMethod { .post }
        var path: String { "/users/me/username" }
        var body: HTTPBody? { .json(Payload(username: username)) }

        private struct Payload: Encodable, Sendable {
            let username: String
        }
    }

    struct Profile: Endpoint {
        typealias Response = User

        let username: String

        var path: String { "/users/\(username)" }
    }

    /// Canonical cursor-paginated endpoint. Copy this shape for every list in the contract.
    struct Followers: Endpoint {
        typealias Response = Page<User>

        let username: String
        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/\(username)/followers" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    static func me() -> Me { Me() }
    static func claimUsername(_ username: String) -> ClaimUsername { ClaimUsername(username: username) }
    static func profile(username: String) -> Profile { Profile(username: username) }
    static func followers(of username: String, cursor: String? = nil) -> Followers {
        Followers(username: username, cursor: cursor)
    }
}
