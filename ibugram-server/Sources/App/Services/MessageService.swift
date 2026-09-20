import Fluent
import Foundation
import IBUgramKit
import Vapor

struct SentMessage: Sendable {
    let message: IBUgramKit.Message
    /// False when the send was a retry that the `(conversation_id, client_id)` index
    /// collapsed onto the original row, which the controller answers with `200`.
    let isNew: Bool
}

struct MessageService: Sendable {
    let database: any Database
    let realtime: RealtimeBroadcaster
    let urls: MediaURLBuilder

    private var conversations: ConversationService {
        ConversationService(database: database, realtime: realtime, urls: urls)
    }

    private var projector: MessageProjector {
        MessageProjector(database: database, urls: urls)
    }

    func history(
        in conversationId: UUID,
        viewer: UUID,
        page: PageRequest
    ) async throws -> Paginated<IBUgramKit.Message> {
        _ = try await conversations.requireMembership(of: conversationId, viewer: viewer)

        let query = MessageRecord.query(on: database)
            .filter(\.$conversation.$id == conversationId)
            .sort(\.$createdAt, .descending)
            .sort(\.$id, .descending)
        if let cursor = page.cursor.flatMap(MessagingCursor.init(encoded:)) {
            query.group(.or) { group in
                group.filter(\.$createdAt < cursor.timestamp)
                group.group(.and) { tie in
                    tie.filter(\.$createdAt == cursor.timestamp)
                    tie.filter(\.$id < cursor.id)
                }
            }
        }

        let rows = try await query.limit(page.limit + 1).all()
        let visible = Array(rows.prefix(page.limit))
        let items = try await projector.project(visible)

        var nextCursor: String?
        if rows.count > page.limit, let last = visible.last, let createdAt = last.createdAt {
            nextCursor = MessagingCursor(timestamp: createdAt, id: try last.requireID()).encoded
        }
        return Paginated(items: items, nextCursor: nextCursor)
    }

    /// Persists, then fans `message_created` out to the other participants. The fan-out runs
    /// after the write is committed and cannot fail the request.
    func send(
        _ body: CreateMessageBody,
        in conversationId: UUID,
        from senderId: UUID
    ) async throws -> SentMessage {
        let membership = try await conversations.requireMembership(of: conversationId, viewer: senderId)
        let trimmedBody = body.body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let mediaIds = body.mediaIds ?? []
        guard !(trimmedBody?.isEmpty ?? true) || !mediaIds.isEmpty else {
            throw APIError.validationFailed("A message needs text or an image.")
        }
        guard (trimmedBody?.count ?? 0) <= 4_000 else {
            throw APIError.validationFailed("A message is at most 4000 characters.")
        }
        try await requireOwnedMedia(mediaIds, uploader: senderId)

        if let existing = try await findByClientId(body.clientId, in: conversationId) {
            return SentMessage(message: try await project(existing), isNew: false)
        }

        let record = MessageRecord()
        record.id = UUID()
        record.$conversation.id = conversationId
        record.$sender.id = senderId
        record.body = (trimmedBody?.isEmpty ?? true) ? nil : trimmedBody
        record.clientId = body.clientId

        do {
            try await store(record, mediaIds: mediaIds, membership: membership)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            guard let existing = try await findByClientId(body.clientId, in: conversationId) else {
                throw APIError.conflict("That message could not be sent. Try again.")
            }
            return SentMessage(message: try await project(existing), isNew: false)
        }

        let message = try await project(record)
        await realtime.send(.messageCreated(MessageCreatedPayload(message: message)), to: membership.otherParticipantIds)
        await realtime.sendUnreadCounts(to: membership.otherParticipantIds, on: database)
        return SentMessage(message: message, isNew: true)
    }

    private func store(
        _ record: MessageRecord,
        mediaIds: [UUID],
        membership: ConversationMembership
    ) async throws {
        let conversationId = try membership.conversation.requireID()
        try await database.transaction { transaction in
            try await record.create(on: transaction)
            let messageId = try record.requireID()
            if !mediaIds.isEmpty {
                let attachments = mediaIds.enumerated().map { position, mediaId in
                    let attachment = MessageMediaRecord()
                    attachment.$message.id = messageId
                    attachment.$media.id = mediaId
                    attachment.position = position
                    return attachment
                }
                try await attachments.create(on: transaction)
            }

            membership.conversation.$lastMessage.id = messageId
            try await membership.conversation.save(on: transaction)

            try await Self.bumpUnreadCounts(
                in: conversationId,
                excluding: record.$sender.id,
                readUpTo: messageId,
                on: transaction
            )
            /// Replying to a message request accepts it, which is what the UI implies when it
            /// offers a text field on a request thread.
            if !membership.participant.hasAccepted {
                membership.participant.hasAccepted = true
                try await membership.participant.save(on: transaction)
            }
        }
    }

    /// One statement, so two simultaneous sends cannot read the same counter and both write
    /// the same incremented value.
    private static func bumpUnreadCounts(
        in conversationId: UUID,
        excluding senderId: UUID,
        readUpTo messageId: UUID,
        on database: any Database
    ) async throws {
        try await database.execute(sql: """
            UPDATE conversation_participants
            SET unread_count = unread_count + 1, updated_at = now()
            WHERE conversation_id = \(bind: conversationId) AND user_id <> \(bind: senderId)
            """)
        try await database.execute(sql: """
            UPDATE conversation_participants
            SET unread_count = 0, last_read_message_id = \(bind: messageId), updated_at = now()
            WHERE conversation_id = \(bind: conversationId) AND user_id = \(bind: senderId)
            """)
    }

    private func findByClientId(_ clientId: UUID, in conversationId: UUID) async throws -> MessageRecord? {
        try await MessageRecord.query(on: database)
            .filter(\.$conversation.$id == conversationId)
            .filter(\.$clientId == clientId)
            .first()
    }

    private func requireOwnedMedia(_ mediaIds: [UUID], uploader: UUID) async throws {
        guard !mediaIds.isEmpty else { return }
        guard mediaIds.count <= IBUgram.maxPostMediaCount else {
            throw APIError.validationFailed("A message carries at most \(IBUgram.maxPostMediaCount) images.")
        }
        let owned = try await MediaRecord.query(on: database)
            .filter(\.$id ~~ mediaIds)
            .filter(\.$uploadedBy.$id == uploader)
            .count()
        guard owned == Set(mediaIds).count else {
            throw APIError.validationFailed("One of those images is not yours to send.")
        }
    }

    private func project(_ record: MessageRecord) async throws -> IBUgramKit.Message {
        guard let message = try await projector.project([record]).first else {
            throw APIError.notFound("That message does not exist.")
        }
        return message
    }
}

/// Turns message rows into DTOs with a fixed number of queries: senders, attachments and
/// read receipts are each loaded once for the whole page.
struct MessageProjector: Sendable {
    let database: any Database
    let urls: MediaURLBuilder

    func project(ids: [UUID]) async throws -> [UUID: IBUgramKit.Message] {
        guard !ids.isEmpty else { return [:] }
        let records = try await MessageRecord.query(on: database)
            .filter(\.$id ~~ ids)
            .all()
        let projected = try await project(records)
        return Dictionary(uniqueKeysWithValues: projected.map { ($0.id, $0) })
    }

    func project(_ records: [MessageRecord]) async throws -> [IBUgramKit.Message] {
        guard !records.isEmpty else { return [] }
        let messageIds = try records.map { try $0.requireID() }
        let senders = try await UserRecord.query(on: database)
            .filter(\.$id ~~ records.map(\.$sender.id))
            .all()
            .reduce(into: [UUID: UserRecord]()) { result, user in
                if let id = user.id { result[id] = user }
            }
        let attachments = try await MessageMediaRecord.query(on: database)
            .filter(\.$message.$id ~~ messageIds)
            .with(\.$media)
            .sort(\.$position)
            .all()
        let reads = try await MessageReadRecord.query(on: database)
            .filter(\.$message.$id ~~ messageIds)
            .all()

        return try records.map { record in
            let messageId = try record.requireID()
            guard let sender = senders[record.$sender.id] else {
                throw APIError.notFound("That message has no sender.")
            }
            return try record.asDTO(
                sender: sender,
                media: attachments.filter { $0.$message.id == messageId }.map(\.media),
                readBy: reads.filter { $0.$message.id == messageId }.map(\.$user.id),
                urls: urls
            )
        }
    }
}