import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Testing
import Vapor
import VaporTesting
@testable import App

/// Messaging runs against its own database so a concurrent suite cannot truncate rows out
/// from under a socket test.
actor MessagingTestDatabase {
    static let shared = MessagingTestDatabase()
    private var isPrepared = false

    func prepareSchema(on app: Application) async throws {
        guard !isPrepared else { return }
        guard let sql = app.db as? any SQLDatabase else { return }
        try await sql.raw("DROP SCHEMA IF EXISTS public CASCADE").run()
        try await sql.raw("CREATE SCHEMA public").run()
        try await app.autoMigrate()
        isPrepared = true
    }
}

func messagingTestConfiguration() -> AppConfiguration {
    var configuration = TestSupport.configuration(for: .testing)
    configuration.database.database = "ibugram_test_msg"
    configuration.publicBaseURL = "http://127.0.0.1:8093"
    return configuration
}

/// `liveServerPort` boots a real HTTP listener, which the WebSocket tests need because an
/// in-memory responder cannot be upgraded.
func withMessagingTestServer<T>(
    liveServerPort: Int? = nil,
    _ body: (TestContext) async throws -> T
) async throws -> T {
    await ExclusiveDatabaseAccess.shared.acquire()
    do {
        let result = try await runMessagingServer(liveServerPort: liveServerPort, body)
        await ExclusiveDatabaseAccess.shared.release()
        return result
    } catch {
        await ExclusiveDatabaseAccess.shared.release()
        throw error
    }
}

private func runMessagingServer<T>(
    liveServerPort: Int?,
    _ body: (TestContext) async throws -> T
) async throws -> T {
    let app = try await Application.make(.testing)
    var liveServerStarted = false
    do {
        try await configure(app, using: messagingTestConfiguration())
        try await MessagingTestDatabase.shared.prepareSchema(on: app)
        if let sql = app.db as? any SQLDatabase {
            let list = TestSupport.tables.joined(separator: ", ")
            try await sql.raw("TRUNCATE TABLE \(unsafeRaw: list) RESTART IDENTITY CASCADE").run()
        }
        await app.dependencies.authRateLimiter.reset()

        let codes = SentCodeLog()
        var dependencies = app.dependencies
        dependencies.emailSender = codes
        dependencies.otp = OTPService(emailSender: codes, hashCost: 4)
        app.dependencies = dependencies

        if let liveServerPort {
            app.http.server.configuration.hostname = "127.0.0.1"
            app.http.server.configuration.port = liveServerPort
            try await app.asyncBoot()
            try await app.server.start(address: .hostname("127.0.0.1", port: liveServerPort))
            liveServerStarted = true
        }

        let result = try await body(TestContext(app: app, codes: codes))
        if liveServerStarted {
            await app.server.shutdown()
        }
        try await app.asyncShutdown()
        return result
    } catch {
        if liveServerStarted {
            await app.server.shutdown()
        }
        try? await app.asyncShutdown()
        throw TestFailure(detail: String(reflecting: error))
    }
}

extension TestContext {
    func openConversation(
        _ session: AuthSession,
        with participantIds: [UUID],
        title: String? = nil
    ) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(
            .POST,
            API.Conversations.create.fullPath,
            headers: authorized(session.accessToken),
            beforeRequest: {
                try $0.content.encode(
                    CreateConversationBody(participantIds: participantIds, title: title)
                )
            }
        )
    }

    func postMessage(
        _ session: AuthSession,
        to conversationId: UUID,
        body: String?,
        clientId: UUID = UUID(),
        mediaIds: [UUID]? = nil
    ) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(
            .POST,
            API.Conversations.sendMessage(id: conversationId).fullPath,
            headers: authorized(session.accessToken),
            beforeRequest: {
                try $0.content.encode(
                    CreateMessageBody(body: body, mediaIds: mediaIds, clientId: clientId)
                )
            }
        )
    }

    func markConversationRead(
        _ session: AuthSession,
        conversationId: UUID,
        upTo messageId: UUID
    ) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(
            .POST,
            API.Conversations.markRead(id: conversationId).fullPath,
            headers: authorized(session.accessToken),
            beforeRequest: {
                try $0.content.encode(MarkConversationReadBody(upToMessageId: messageId))
            }
        )
    }

    func listConversations(
        _ session: AuthSession,
        filter: ConversationFilter
    ) async throws -> Paginated<Conversation> {
        let response = try await app.testing().sendRequest(
            .GET,
            API.Conversations.list.fullPath + "?filter=\(filter.rawValue)",
            headers: authorized(session.accessToken)
        )
        #expect(response.status == .ok)
        return try response.content.decode(Paginated<Conversation>.self)
    }

    func insertFollow(follower: UUID, followee: UUID) async throws {
        try await FollowRecord(followerId: follower, followeeId: followee).create(on: app.db)
    }

    func insertBlock(blocker: UUID, blocked: UUID) async throws {
        try await BlockRecord(blockerId: blocker, blockedId: blocked).create(on: app.db)
    }

    func participant(in conversationId: UUID, for userId: UUID) async throws -> ConversationParticipantRecord {
        try #require(
            try await ConversationParticipantRecord.query(on: app.db)
                .filter(\.$conversation.$id == conversationId)
                .filter(\.$user.$id == userId)
                .first()
        )
    }
}

@Suite("Conversations", .serialized)
struct ConversationTests {
    private let amina = "amina.hodzic@stu.ibu.edu.ba"
    private let emir = "emir.kovacevic@stu.ibu.edu.ba"

    @Test("Opening a direct conversation twice returns the one that already exists")
    func directConversationsAreIdempotent() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)

            let first = try await context.openConversation(sender, with: [recipient.user.id])
            #expect(first.status == .created)
            let created = try first.content.decode(Conversation.self)
            #expect(created.kind == .direct)
            #expect(created.participants.count == 2)

            let second = try await context.openConversation(sender, with: [recipient.user.id])
            #expect(second.status == .ok)
            #expect(try second.content.decode(Conversation.self).id == created.id)

            /// The other side opening the same pair must land on the same row, which is what the
            /// sorted `direct_key` buys.
            let reversed = try await context.openConversation(recipient, with: [sender.user.id])
            #expect(reversed.status == .ok)
            #expect(try reversed.content.decode(Conversation.self).id == created.id)

            #expect(try await ConversationRecord.query(on: context.app.db).count() == 1)
        }
    }

    @Test("A conversation from someone the recipient does not follow arrives as a request")
    func unfollowedSenderCreatesRequest() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)

            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            _ = try await context.postMessage(sender, to: conversation.id, body: "Hi!")

            let requests = try await context.listConversations(recipient, filter: .requests)
            #expect(requests.items.map(\.id) == [conversation.id])
            #expect(requests.items.first?.isRequest == true)
            #expect(try await context.listConversations(recipient, filter: .inbox).items.isEmpty)

            /// The sender always sees their own thread in the inbox.
            #expect(try await context.listConversations(sender, filter: .inbox).items.count == 1)
        }
    }

    @Test("Accepting a request moves the conversation into the inbox")
    func acceptMovesRequestToInbox() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            let accepted = try await context.app.testing().sendRequest(
                .POST,
                API.Conversations.accept(id: conversation.id).fullPath,
                headers: context.authorized(recipient.accessToken)
            )
            #expect(accepted.status == .ok)
            #expect(try accepted.content.decode(Conversation.self).isRequest == false)

            #expect(try await context.listConversations(recipient, filter: .inbox).items.count == 1)
            #expect(try await context.listConversations(recipient, filter: .requests).items.isEmpty)
        }
    }

    @Test("A conversation opened by someone the recipient follows is not a request")
    func followedSenderSkipsRequests() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            try await context.insertFollow(follower: recipient.user.id, followee: sender.user.id)

            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            let inbox = try await context.listConversations(recipient, filter: .inbox)
            #expect(inbox.items.map(\.id) == [conversation.id])
        }
    }

    @Test("A blocked user can neither open nor send to a conversation")
    func blockedUsersAreRefused() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            try await context.insertBlock(blocker: recipient.user.id, blocked: sender.user.id)

            let reopened = try await context.openConversation(sender, with: [recipient.user.id])
            #expect(reopened.status == .forbidden)
            #expect(reopened.apiError?.code == .forbidden)

            let sent = try await context.postMessage(sender, to: conversation.id, body: "Hello?")
            #expect(sent.status == .forbidden)

            let read = try await context.app.testing().sendRequest(
                .GET,
                API.Conversations.messages(id: conversation.id).fullPath,
                headers: context.authorized(sender.accessToken)
            )
            #expect(read.status == .forbidden)
        }
    }

    @Test("A group conversation keeps its title and every participant")
    func groupConversationsAreCreated() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: amina)
            let second = try await context.signIn(as: emir)
            let third = try await context.signIn(as: "lejla.b@stu.ibu.edu.ba")

            let response = try await context.openConversation(
                owner,
                with: [second.user.id, third.user.id],
                title: "Thesis group"
            )
            #expect(response.status == .created)
            let conversation = try response.content.decode(Conversation.self)
            #expect(conversation.kind == .group)
            #expect(conversation.title == "Thesis group")
            #expect(conversation.participants.count == 3)
        }
    }

    @Test("Messaging endpoints require a bearer token")
    func messagingRequiresAuthentication() async throws {
        try await withMessagingTestServer { context in
            let conversationId = UUID()
            let unauthenticated: [(HTTPMethod, String)] = [
                (.GET, API.Conversations.list.fullPath),
                (.POST, API.Conversations.create.fullPath),
                (.GET, API.Conversations.messages(id: conversationId).fullPath),
                (.POST, API.Conversations.sendMessage(id: conversationId).fullPath),
                (.POST, API.Conversations.markRead(id: conversationId).fullPath),
                (.POST, API.Conversations.accept(id: conversationId).fullPath),
                (.GET, API.Notifications.list.fullPath),
                (.GET, API.Notifications.unreadCount.fullPath),
                (.POST, API.Notifications.markRead.fullPath)
            ]
            for (method, path) in unauthenticated {
                let response = try await context.app.testing().sendRequest(method, path)
                #expect(response.status == .unauthorized, "\(method) \(path)")
            }
        }
    }

    @Test("A conversation needs somebody else in it")
    func conversationsNeedAnotherParticipant() async throws {
        try await withMessagingTestServer { context in
            let session = try await context.signIn(as: amina)
            let response = try await context.openConversation(session, with: [session.user.id])
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }
}
