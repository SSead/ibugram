import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Reports", .serialized)
struct ReportTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"
    private let other = "second.student@stu.ibu.edu.ba"

    @Test("A signed-in user can report another user")
    func reportUserSucceeds() async throws {
        try await withCommunityTestServer { context in
            let reporter = try await context.signIn(as: student)
            let target = try await context.signIn(as: other)
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Moderation.report.fullPath,
                headers: context.authorized(reporter.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateReportBody(
                        userId: target.user.id,
                        reason: .spam
                    ))
                }
            )
            #expect(response.status == .created)
            let receipt = try response.content.decode(ReportReceipt.self)
            #expect(receipt.status == .open)
        }
    }

    @Test("An unauthenticated report is rejected")
    func reportRequiresAuth() async throws {
        try await withCommunityTestServer { context in
            let response = try await context.app.testing().sendRequest(.POST, API.Moderation.report.fullPath)
            #expect(response.status == .unauthorized)
        }
    }

    @Test("A report with two targets is rejected as validation_failed")
    func twoTargetsAreRejected() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Moderation.report.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateReportBody(
                        postId: UUID(),
                        commentId: UUID(),
                        reason: .harassment
                    ))
                }
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }

    @Test("A report with no target is rejected as validation_failed")
    func missingTargetIsRejected() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Moderation.report.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: {
                    try $0.content.encode(CreateReportBody(reason: .other))
                }
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }
}
