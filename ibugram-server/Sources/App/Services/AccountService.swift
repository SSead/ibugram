import Fluent
import Foundation
import IBUgramKit
import Vapor

struct AccountService: Sendable {
    /// The first successful verification of an address is also the sign-up; role and the
    /// faculty badge are derived from the domain, never from client input.
    func findOrCreateUser(email: String, on database: any Database) async throws -> UserRecord {
        if let existing = try await UserRecord.query(on: database).filter(\.$email == email).first() {
            return existing
        }
        guard let role = EmailAddress.role(for: email) else {
            throw APIError(code: .domainNotAllowed, message: "That address is not a university address.")
        }
        let user = UserRecord(email: email, role: role)
        try await user.save(on: database)
        return user
    }

    func applyProfileUpdate(_ update: UpdateProfileBody, to user: UserRecord) throws {
        if let displayName = update.displayName {
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (1...60).contains(trimmed.count) else {
                throw APIError.validationFailed(
                    "Your display name must be between 1 and 60 characters.",
                    details: ["display_name": .string("must be 1 to 60 characters")]
                )
            }
            user.displayName = trimmed
        }
        if let bio = update.bio {
            guard bio.count <= 300 else {
                throw APIError.validationFailed(
                    "Your bio is too long.",
                    details: ["bio": .string("must be 300 characters or fewer")]
                )
            }
            user.bio = bio
        }
        if let department = update.department {
            user.department = department
        }
        if let yearOfStudy = update.yearOfStudy {
            guard (1...8).contains(yearOfStudy) else {
                throw APIError.validationFailed(
                    "That year of study is not valid.",
                    details: ["year_of_study": .string("must be between 1 and 8")]
                )
            }
            user.yearOfStudy = yearOfStudy
        }
    }

    func assignAvatar(mediaId: UUID, to user: UserRecord, on database: any Database) async throws {
        guard let media = try await MediaRecord.find(mediaId, on: database) else {
            throw APIError.notFound("That image does not exist.")
        }
        guard media.$uploadedBy.id == user.id else {
            throw APIError.forbidden("You can only use media you uploaded.")
        }
        user.$avatarMedia.id = mediaId
    }

    func claimUsername(_ candidate: String, for user: UserRecord, on database: any Database) async throws {
        let normalized = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let problem = Username.validate(normalized) {
            throw APIError.validationFailed(
                "That username is not allowed.",
                details: ["username": .string(problem.rawValue)]
            )
        }
        let taken = try await UserRecord.query(on: database)
            .filter(\.$username == normalized)
            .filter(\.$id != user.requireID())
            .count()
        guard taken == 0 else {
            throw APIError(code: .usernameTaken, message: "That username is already taken.")
        }
        user.username = normalized
        do {
            try await user.save(on: database)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            throw APIError(code: .usernameTaken, message: "That username is already taken.")
        }
    }
}
