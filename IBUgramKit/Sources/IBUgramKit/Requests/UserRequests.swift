import Foundation

/// Absent fields are left unchanged; the contract has no representation for clearing a field.
public struct UpdateProfileBody: Codable, Sendable, Hashable {
    public var displayName: String?
    public var bio: String?
    public var department: String?
    public var yearOfStudy: Int?
    public var avatarMediaId: UUID?

    public init(
        displayName: String? = nil,
        bio: String? = nil,
        department: String? = nil,
        yearOfStudy: Int? = nil,
        avatarMediaId: UUID? = nil
    ) {
        self.displayName = displayName
        self.bio = bio
        self.department = department
        self.yearOfStudy = yearOfStudy
        self.avatarMediaId = avatarMediaId
    }
}

public struct SetUsernameBody: Codable, Sendable, Hashable {
    public var username: String

    public init(username: String) {
        self.username = username
    }
}

public struct ReportBody: Codable, Sendable, Hashable {
    public var subject: ReportSubject
    public var subjectId: UUID
    public var reason: ReportReason
    public var detail: String?

    public init(subject: ReportSubject, subjectId: UUID, reason: ReportReason, detail: String? = nil) {
        self.subject = subject
        self.subjectId = subjectId
        self.reason = reason
        self.detail = detail
    }
}
