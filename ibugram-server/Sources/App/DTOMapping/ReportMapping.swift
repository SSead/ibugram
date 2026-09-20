import Foundation
import IBUgramKit
import Vapor

struct CreateReportBody: Content {
    var postId: UUID?
    var commentId: UUID?
    var userId: UUID?
    var reason: ReportReason
    var detail: String?

    enum CodingKeys: String, CodingKey {
        case postId
        case commentId
        case userId
        case reason
        case detail
        case subject
        case subjectId
    }

    init(postId: UUID? = nil, commentId: UUID? = nil, userId: UUID? = nil, reason: ReportReason, detail: String? = nil) {
        self.postId = postId
        self.commentId = commentId
        self.userId = userId
        self.reason = reason
        self.detail = detail
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = try container.decodeIfPresent(UUID.self, forKey: .postId)
        commentId = try container.decodeIfPresent(UUID.self, forKey: .commentId)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        reason = try container.decode(ReportReason.self, forKey: .reason)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)

        if postId == nil, commentId == nil, userId == nil,
           let subject = try container.decodeIfPresent(ReportSubject.self, forKey: .subject),
           let subjectId = try container.decodeIfPresent(UUID.self, forKey: .subjectId)
        {
            switch subject {
            case .post: postId = subjectId
            case .comment: commentId = subjectId
            case .user: userId = subjectId
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(postId, forKey: .postId)
        try container.encodeIfPresent(commentId, forKey: .commentId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(reason, forKey: .reason)
        try container.encodeIfPresent(detail, forKey: .detail)
    }

    var targetCount: Int {
        [postId, commentId, userId].compactMap { $0 }.count
    }
}

struct ReportReceipt: Content {
    var id: UUID
    var status: ReportStatus
}
