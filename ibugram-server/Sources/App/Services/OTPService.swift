import Fluent
import Foundation
import IBUgramKit
import Vapor

struct IssuedChallenge: Sendable {
    let code: String
    let expiresAt: Date
    let resendAfter: Int
}

struct OTPService: Sendable {
    let emailSender: any EmailSender
    let hashCost: Int

    /// Never returns a different shape for a known and an unknown address: the account is
    /// not looked up at all, so the response cannot distinguish them.
    func issueChallenge(
        toEmail email: String,
        clientAddress: String?,
        on database: any Database
    ) async throws -> IssuedChallenge {
        let now = Date()
        try await enforceThrottle(for: email, now: now, on: database)
        try await invalidateOutstandingChallenges(for: email, on: database)

        let code = Self.generateCode()
        let expiresAt = now.addingTimeInterval(IBUgram.otpLifetime)
        let challenge = OTPChallengeRecord(
            email: email,
            codeHash: try Bcrypt.hash(code, cost: hashCost),
            expiresAt: expiresAt,
            requestedIp: clientAddress
        )
        try await challenge.save(on: database)
        try await emailSender.sendVerificationCode(
            code,
            to: email,
            expiresIn: Int(IBUgram.otpLifetime / 60)
        )
        return IssuedChallenge(
            code: code,
            expiresAt: expiresAt,
            resendAfter: Int(IBUgram.otpResendInterval)
        )
    }

    func consumeChallenge(forEmail email: String, code: String, on database: any Database) async throws {
        let now = Date()
        guard let challenge = try await OTPChallengeRecord.query(on: database)
            .filter(\.$email == email)
            .filter(\.$consumedAt == nil)
            .sort(\.$createdAt, .descending)
            .first()
        else {
            throw APIError(code: .otpInvalid, message: "That code is not correct.")
        }

        guard challenge.expiresAt > now else {
            throw APIError(code: .otpExpired, message: "That code has expired. Request a new one.")
        }
        guard challenge.attemptCount < IBUgram.otpMaxAttempts else {
            throw APIError(
                code: .otpThrottled,
                message: "Too many attempts for this code. Request a new one."
            )
        }

        guard try Bcrypt.verify(code, created: challenge.codeHash) else {
            challenge.attemptCount += 1
            if challenge.attemptCount >= IBUgram.otpMaxAttempts {
                challenge.consumedAt = now
            }
            try await challenge.save(on: database)
            throw APIError(code: .otpInvalid, message: "That code is not correct.")
        }

        challenge.consumedAt = now
        try await challenge.save(on: database)
    }

    private func enforceThrottle(for email: String, now: Date, on database: any Database) async throws {
        let sinceLastRequest = try await OTPChallengeRecord.query(on: database)
            .filter(\.$email == email)
            .filter(\.$createdAt >= now.addingTimeInterval(-IBUgram.otpResendInterval))
            .count()
        if sinceLastRequest > 0 {
            throw Self.throttled(retryAfter: Int(IBUgram.otpResendInterval))
        }

        let withinHour = try await OTPChallengeRecord.query(on: database)
            .filter(\.$email == email)
            .filter(\.$createdAt >= now.addingTimeInterval(-3600))
            .count()
        if withinHour >= IBUgram.otpHourlyLimit {
            throw Self.throttled(retryAfter: 3600)
        }
    }

    private func invalidateOutstandingChallenges(for email: String, on database: any Database) async throws {
        try await OTPChallengeRecord.query(on: database)
            .filter(\.$email == email)
            .filter(\.$consumedAt == nil)
            .set(\.$consumedAt, to: Date())
            .update()
    }

    private static func throttled(retryAfter seconds: Int) -> APIError {
        APIError(
            code: .otpThrottled,
            message: "A code was already sent. Wait before requesting another.",
            details: ["retry_after": .number(Double(seconds))]
        )
    }

    private static func generateCode() -> String {
        let upperBound = Int(pow(10.0, Double(IBUgram.otpDigitCount)))
        return String(format: "%0\(IBUgram.otpDigitCount)d", Int.random(in: 0..<upperBound))
    }
}
