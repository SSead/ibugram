import Fluent
import Foundation
import IBUgramKit
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Users.me, use: currentUser)
        authenticated.on(API.Users.updateMe, use: updateCurrentUser)
        authenticated.on(API.Users.setUsername, use: setUsername)
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
}

extension UpdateProfileBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("display_name", as: String?.self, is: .nil || .count(1...60), required: false)
        validations.add("bio", as: String?.self, is: .nil || .count(...300), required: false)
        validations.add("department", as: String?.self, is: .nil || .count(1...120), required: false)
        validations.add("year_of_study", as: Int?.self, is: .nil || .range(1...8), required: false)
    }
}
