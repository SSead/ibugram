import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Health, errors and stubs", .serialized)
struct InfrastructureTests {
    @Test("Health reports the database it is actually talking to")
    func healthIsHonest() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, API.health.fullPath)
            #expect(response.status == .ok)

            let health = try response.content.decode(HealthStatus.self)
            #expect(health.status == "ok")
            #expect(health.database == "ok")
            #expect(health.version == "test")
        }
    }

    @Test("Health is also reachable under the versioned prefix")
    func healthIsVersioned() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, API.versionedHealth.fullPath)
            #expect(response.status == .ok)
        }
    }

    @Test("The reserved list is empty once every contract endpoint is implemented")
    func reservedEndpointsAreStubbed() {
        #expect(ReservedEndpointController.reserved.isEmpty)
    }

    @Test("Protected endpoints still require authentication")
    func reservedEndpointsAreProtected() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, API.Conversations.list.fullPath)
            #expect(response.status == .unauthorized)
        }
    }

    @Test("The WebSocket upgrade does not demand a bearer header")
    func webSocketStubIsNotBehindHeaderAuth() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, API.webSocket.fullPath)
            #expect(response.status != .unauthorized)
        }
    }

    @Test("A malformed body produces validation_failed, never a stack trace")
    func malformedBodiesAreHandled() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.requestCode.fullPath,
                beforeRequest: {
                    $0.headers.contentType = .json
                    $0.body = ByteBuffer(string: #"{"not_email": 1}"#)
                }
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
            #expect(response.body.string.contains("Fatal") == false)
            #expect(response.body.string.contains("Sources/") == false)
        }
    }

    @Test("An unknown path returns the error envelope rather than Vapor's default page")
    func unknownPathsUseTheEnvelope() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, "/api/v1/nope")
            #expect(response.status == .notFound)
            #expect(response.apiError?.code == .notFound)
        }
    }

    @Test("The debug code is present in development and absent everywhere else")
    func debugCodeIsDevelopmentOnly() async throws {
        #expect(TestSupport.configuration(for: .development).exposesDebugCode)
        #expect(TestSupport.configuration(for: .production).exposesDebugCode == false)
        #expect(TestSupport.configuration(for: .testing).exposesDebugCode == false)

        try await withTestServer(environment: .development) { context in
            let response = try await context.requestCode(for: "amina.hodzic@stu.ibu.edu.ba")
            let payload = try response.content.decode(RequestCodeResponse.self)
            let issued = try #require(payload.debugCode)
            #expect(issued.count == IBUgram.otpDigitCount)
            #expect(issued == (await context.codes.latestCode(for: "amina.hodzic@stu.ibu.edu.ba")))
        }
    }

    @Test("Production refuses to start without an explicit signing secret")
    func productionRequiresASecret() {
        #expect(throws: ConfigurationError.self) {
            try AppConfiguration.load(for: .production)
        }
    }
}

@Suite("Schema", .serialized)
struct SchemaTests {
    @Test("Counter triggers keep the denormalised follower counts correct")
    func followCountsAreMaintained() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: "one@stu.ibu.edu.ba")
            let second = try await context.signIn(as: "two@stu.ibu.edu.ba")
            let follow = FollowRecord(followerId: first.user.id, followeeId: second.user.id)
            try await follow.save(on: context.app.db)

            let followee = try #require(try await UserRecord.find(second.user.id, on: context.app.db))
            let follower = try #require(try await UserRecord.find(first.user.id, on: context.app.db))
            #expect(followee.followerCount == 1)
            #expect(follower.followingCount == 1)

            try await follow.delete(on: context.app.db)
            let afterUnfollow = try #require(try await UserRecord.find(second.user.id, on: context.app.db))
            #expect(afterUnfollow.followerCount == 0)
        }
    }

    @Test("The database refuses a duplicate follow and a self follow")
    func followInvariantsAreEnforced() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: "one@stu.ibu.edu.ba")
            let second = try await context.signIn(as: "two@stu.ibu.edu.ba")
            try await FollowRecord(followerId: first.user.id, followeeId: second.user.id)
                .save(on: context.app.db)

            await #expect(throws: (any Error).self) {
                try await FollowRecord(followerId: first.user.id, followeeId: second.user.id)
                    .save(on: context.app.db)
            }
            await #expect(throws: (any Error).self) {
                try await FollowRecord(followerId: first.user.id, followeeId: first.user.id)
                    .save(on: context.app.db)
            }
        }
    }

    @Test("Full-text columns are generated for posts and users")
    func searchVectorsExist() async throws {
        try await withTestServer { context in
            let sql = try #require(context.app.db as? any SQLDatabase)
            let rows = try await sql.raw("""
                SELECT table_name FROM information_schema.columns
                WHERE column_name = 'search_vector' ORDER BY table_name
                """).all()
            let names = try rows.map { try $0.decode(column: "table_name", as: String.self) }
            #expect(names == ["posts", "users"])
        }
    }

    @Test("Every table named in the data model exists after migrating")
    func schemaIsComplete() async throws {
        try await withTestServer { context in
            let sql = try #require(context.app.db as? any SQLDatabase)
            let rows = try await sql.raw("""
                SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'
                """).all()
            let present = Set(try rows.map { try $0.decode(column: "table_name", as: String.self) })
            #expect(Set(TestSupport.tables).isSubset(of: present))
        }
    }
}
