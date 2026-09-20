import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Messages", .serialized)
struct MessageTests {
    private let amina = "amina.hodzic@stu.ibu.edu.ba"
    private let emir = "emir.kovacevic@stu.ibu.edu.ba"

    @Test("A retry with the same client_id returns the original message instead of a duplicate")
    func duplicateClientIdIsIdempotent() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            let clientId = UUID()
            let first = try await context.postMessage(
                sender,
                to: conversation.id,
                body: "Are we still meeting?",
                clientId: clientId
            )
            #expect(first.status == .created)
            let original = try first.content.decode(IBUgramKit.Message.self)

            let retry = try await context.postMessage(
                sender,
                to: conversation.id,
                body: "Are we still meeting?",
                clientId: clientId
            )
            #expect(retry.status == .ok)
            #expect(try retry.content.decode(IBUgramKit.Message.self).id == original.id)

            #expect(try await MessageRecord.query(on: context.app.db).count() == 1)
            #expect(try await context.participant(in: conversation.id, for: recipient.user.id).unreadCount == 1)
        }
    }

    @Test("Sending raises the recipient's unread count and a read receipt clears it")
    func unreadCountsFollowSendsAndReads() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            var lastMessageId = UUID()
            for index in 1...3 {
                let response = try await context.postMessage(
                    sender,
                    to: conversation.id,
                    body: "Message \(index)"
                )
                lastMessageId = try response.content.decode(IBUgramKit.Message.self).id
            }

            #expect(try await context.participant(in: conversation.id, for: recipient.user.id).unreadCount == 3)
            #expect(try await context.participant(in: conversation.id, for: sender.user.id).unreadCount == 0)

            let inbox = try await context.listConversations(recipient, filter: .requests)
            #expect(inbox.items.first?.unreadCount == 3)

            let read = try await context.markConversationRead(
                recipient,
                conversationId: conversation.id,
                upTo: lastMessageId
            )
            #expect(read.status == .ok)
            #expect(try read.content.decode(UnreadCount.self).count == 0)

            let participant = try await context.participant(in: conversation.id, for: recipient.user.id)
            #expect(participant.unreadCount == 0)
            #expect(participant.$lastReadMessage.id == lastMessageId)
            #expect(try await MessageReadRecord.query(on: context.app.db).count() == 3)

            /// The sender now sees the thread as read.
            let history = try await context.app.testing().sendRequest(
                .GET,
                API.Conversations.messages(id: conversation.id).fullPath,
                headers: context.authorized(sender.accessToken)
            )
            let messages = try history.content.decode(Paginated<IBUgramKit.Message>.self)
            #expect(messages.items.first?.delivery == .read)
            #expect(messages.items.first?.readBy == [recipient.user.id])
        }
    }

    @Test("A second read receipt for the same cursor does not double-count")
    func repeatedReadReceiptsAreHarmless() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            let message = try await context.postMessage(sender, to: conversation.id, body: "One")
                .content.decode(IBUgramKit.Message.self)

            for _ in 0..<2 {
                let response = try await context.markConversationRead(
                    recipient,
                    conversationId: conversation.id,
                    upTo: message.id
                )
                #expect(response.status == .ok)
            }
            #expect(try await MessageReadRecord.query(on: context.app.db).count() == 1)
            #expect(try await context.participant(in: conversation.id, for: recipient.user.id).unreadCount == 0)
        }
    }

    @Test("History is newest first and pages with a cursor")
    func historyPaginates() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            for index in 1...5 {
                _ = try await context.postMessage(sender, to: conversation.id, body: "Message \(index)")
            }

            let firstPage = try await context.app.testing().sendRequest(
                .GET,
                API.Conversations.messages(id: conversation.id).fullPath + "?limit=2",
                headers: context.authorized(recipient.accessToken)
            ).content.decode(Paginated<IBUgramKit.Message>.self)
            #expect(firstPage.items.map(\.body) == ["Message 5", "Message 4"])
            let cursor = try #require(firstPage.nextCursor)

            let secondPage = try await context.app.testing().sendRequest(
                .GET,
                API.Conversations.messages(id: conversation.id).fullPath + "?limit=2&cursor=\(cursor)",
                headers: context.authorized(recipient.accessToken)
            ).content.decode(Paginated<IBUgramKit.Message>.self)
            #expect(secondPage.items.map(\.body) == ["Message 3", "Message 2"])
        }
    }

    @Test("Replying to a message request accepts it")
    func replyingAcceptsTheRequest() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            _ = try await context.postMessage(sender, to: conversation.id, body: "Hello")

            let reply = try await context.postMessage(recipient, to: conversation.id, body: "Hi")
            #expect(reply.status == .created)
            #expect(try await context.participant(in: conversation.id, for: recipient.user.id).hasAccepted)
            #expect(try await context.listConversations(recipient, filter: .inbox).items.count == 1)
        }
    }

    @Test("Somebody who is not a participant cannot read or write the conversation")
    func nonParticipantsAreRefused() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let stranger = try await context.signIn(as: "stranger@stu.ibu.edu.ba")
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            let read = try await context.app.testing().sendRequest(
                .GET,
                API.Conversations.messages(id: conversation.id).fullPath,
                headers: context.authorized(stranger.accessToken)
            )
            #expect(read.status == .notFound)

            let sent = try await context.postMessage(stranger, to: conversation.id, body: "Let me in")
            #expect(sent.status == .notFound)
        }
    }

    @Test("A message with neither text nor media is rejected")
    func emptyMessagesAreRejected() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            let response = try await context.postMessage(sender, to: conversation.id, body: "   ")
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }

    @Test("A read receipt for a message in another conversation is refused")
    func readReceiptsAreScopedToTheConversation() async throws {
        try await withMessagingTestServer { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let third = try await context.signIn(as: "lejla.b@stu.ibu.edu.ba")
            let first = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            let other = try await context.openConversation(sender, with: [third.user.id])
                .content.decode(Conversation.self)
            let strayMessage = try await context.postMessage(sender, to: other.id, body: "Elsewhere")
                .content.decode(IBUgramKit.Message.self)

            let response = try await context.markConversationRead(
                recipient,
                conversationId: first.id,
                upTo: strayMessage.id
            )
            #expect(response.status == .notFound)
        }
    }
}
