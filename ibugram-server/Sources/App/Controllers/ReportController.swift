import Fluent
import Foundation
import IBUgramKit
import Vapor

struct ReportController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Moderation.report, use: create)
    }

    private func create(_ request: Request) async throws -> Response {
        let reporter = try request.requireAuthenticatedUser()
        try CreateReportBody.validate(content: request)
        let body = try request.content.decode(CreateReportBody.self)
        let receipt = try await request.dependencies.reports.create(
            body,
            reporterId: reporter.id,
            on: request.db
        )
        return try Response.json(receipt, status: .created)
    }
}

extension CreateReportBody: Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("reason", as: String.self, is: !.empty)
        validations.add("detail", as: String?.self, is: .nil || .count(...2_000), required: false)
    }
}
