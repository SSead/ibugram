import Fluent
import Foundation
import IBUgramKit
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.on(Endpoint(.get, "/users/:username/available"), use: usernameAvailable)

        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Users.me, use: currentUser)
        authenticated.on(API.Users.updateMe, use: updateCurrentUser)
        authenticated.on(API.Users.setUsername, use: setUsername)
        authenticated.on(API.Users.suggested, use: suggested)
        authenticated.on(API.Users.profileTemplate, use: profile)
        authenticated.on(API.Users.profilePostsTemplate, use: profilePosts)
        authenticated.on(API.Users.followersTemplate, use: followers)
        authenticated.on(API.Users.followingTemplate, use: following)
    }

    private func currentUser(_ request: Request) async throws -> Response {
        let user = try request.requireCurrentUserRecord()
        return try Response.json(try user.asDTO(urls: request.dependencies.urls))
    }

    private func updateCurrentUser(_ request: Request) async throws -> Response {
        let user = try request.requireCurrentUserRecord()
        try UpdateProfileBody.validate(content: request)
        let body = try request.content.decode(UpdateProfileBody.self)

        try request.dependencies.accounts.applyProfileUpdate(body, to: user)
        if let avatarMediaId = body.avatarMediaId {
            try await request.dependencies.accounts.assignAvatar(
                mediaId: avatarMediaId,
                to: user,
                on: request.db
            )
        }
        try await user.save(on: request.db)
        return try Response.json(try user.asDTO(urls: request.dependencies.urls))
    }

    private func setUsername(_ request: Request) async throws -> Response {
        let user = try request.requireCurrentUserRecord()
        let body = try request.content.decode(SetUsernameBody.self)
        try await request.dependencies.accounts.claimUsername(body.username, for: user, on: request.db)
        return try Response.json(try user.asDTO(urls: request.dependencies.urls))
    }

    private func usernameAvailable(_ request: Request) async throws -> Response {
        let username = try requireUsername(request)
        let payload = try await SocialService().usernameAvailability(username, on: request.db)
        return try Response.json(payload)
    }

    private func profile(_ request: Request) async throws -> Response {
        let user = try await SocialService().profile(
            username: try requireUsername(request),
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(user)
    }

    private func profilePosts(_ request: Request) async throws -> Response {
        let page = try await PostService().postsForUsername(
            try requireUsername(request),
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func followers(_ request: Request) async throws -> Response {
        let page = try await SocialService().followers(
            username: try requireUsername(request),
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func following(_ request: Request) async throws -> Response {
        let page = try await SocialService().following(
            username: try requireUsername(request),
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func suggested(_ request: Request) async throws -> Response {
        let page = try await SocialService().suggestedUsers(
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func requireUsername(_ request: Request) throws -> String {
        guard let username = request.parameters.get("username"), !username.isEmpty else {
            throw APIError.validationFailed("A username is required.")
        }
        return username
    }
}

extension UpdateProfileBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("display_name", as: String?.self, is: .nil || .count(1...60), required: false)
        validations.add("bio", as: String?.self, is: .nil || .count(...300), required: false)
        validations.add("department", as: String?.self, is: .nil || .count(1...120), required: false)
        validations.add("year_of_study", as: Int?.self, is: .nil || .range(1...8), required: false)
    }
}
