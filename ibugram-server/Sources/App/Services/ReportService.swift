import Fluent
import Foundation
import IBUgramKit
import Vapor

struct ReportService: Sendable {
    func create(
        _ body: CreateReportBody,
        reporterId: UUID,
        on database: any Database
    ) async throws -> ReportReceipt {
        guard body.targetCount == 1 else {
            throw APIError.validationFailed(
                "A report must name exactly one target.",
                details: ["target": .string("exactly one of post_id, comment_id, user_id")]
            )
        }

        let record = ReportRecord()
        record.id = UUID()
        record.$reporter.id = reporterId
        record.status = .open
        record.reason = body.reason
        record.detail = body.detail

        if let postId = body.postId {
            guard try await PostRecord.find(postId, on: database) != nil else {
                throw APIError.notFound("That post does not exist.")
            }
            record.subject = .post
            record.$post.id = postId
        } else if let commentId = body.commentId {
            guard try await CommentRecord.find(commentId, on: database) != nil else {
                throw APIError.notFound("That comment does not exist.")
            }
            record.subject = .comment
            record.$comment.id = commentId
        } else if let userId = body.userId {
            guard try await UserRecord.find(userId, on: database) != nil else {
                throw APIError.notFound("That user does not exist.")
            }
            record.subject = .user
            record.$subjectUser.id = userId
        }

        try await record.create(on: database)
        return ReportReceipt(id: try record.requireID(), status: record.status)
    }
}

extension AppServices {
    var reports: ReportService { ReportService() }
}
