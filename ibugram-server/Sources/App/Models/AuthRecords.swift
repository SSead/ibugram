import Fluent
import Foundation
import IBUgramKit

final class OTPChallengeRecord: Model, @unchecked Sendable {
    static let schema = "otp_challenges"

    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @Field(key: "code_hash") var codeHash: String
    @Field(key: "attempt_count") var attemptCount: Int
    @Field(key: "expires_at") var expiresAt: Date
    @OptionalField(key: "consumed_at") var consumedAt: Date?
    @OptionalField(key: "requested_ip") var requestedIp: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(email: String, codeHash: String, expiresAt: Date, requestedIp: String?) {
        self.email = email
        self.codeHash = codeHash
        self.attemptCount = 0
        self.expiresAt = expiresAt
        self.requestedIp = requestedIp
    }

    func isUsable(at moment: Date) -> Bool {
        consumedAt == nil && expiresAt > moment && attemptCount < IBUgram.otpMaxAttempts
    }
}

enum SessionRevocationReason: String, Codable, Sendable, CaseIterable {
    case rotated
    case loggedOut = "logged_out"
    case revokedByUser = "revoked_by_user"
    case reuseDetected = "reuse_detected"
    case expired
}

final class AuthSessionRecord: Model, @unchecked Sendable {
    static let schema = "auth_sessions"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: UserRecord
    @Field(key: "family_id") var familyId: UUID
    @Field(key: "token_hash") var tokenHash: String
    @OptionalField(key: "device_name") var deviceName: String?
    @OptionalField(key: "user_agent") var userAgent: String?
    @OptionalField(key: "ip_address") var ipAddress: String?
    @Field(key: "expires_at") var expiresAt: Date
    @Field(key: "last_used_at") var lastUsedAt: Date
    @OptionalField(key: "revoked_at") var revokedAt: Date?
    @OptionalField(key: "revoked_reason") var revokedReason: SessionRevocationReason?
    @OptionalParent(key: "replaced_by_id") var replacedBy: AuthSessionRecord?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        userId: UUID,
        familyId: UUID,
        tokenHash: String,
        deviceName: String?,
        userAgent: String?,
        ipAddress: String?,
        expiresAt: Date,
        now: Date
    ) {
        self.$user.id = userId
        self.familyId = familyId
        self.tokenHash = tokenHash
        self.deviceName = deviceName
        self.userAgent = userAgent
        self.ipAddress = ipAddress
        self.expiresAt = expiresAt
        self.lastUsedAt = now
    }

    func isActive(at moment: Date) -> Bool {
        revokedAt == nil && expiresAt > moment
    }
}
