import Fluent
import Foundation
import IBUgramKit
import Vapor

/// Keyset pagination over `(timestamp, id)`. Offsets would skip or repeat rows as new
/// messages and conversations arrive between two page requests.
struct MessagingCursor: Sendable, Hashable {
    let timestamp: Date
    let id: UUID

    init(timestamp: Date, id: UUID) {
        self.timestamp = timestamp
        self.id = id
    }

    init?(encoded: String) {
        guard let data = Data(base64Encoded: encoded),
              let text = String(data: data, encoding: .utf8)
        else { return nil }
        let parts = text.split(separator: "|")
        guard parts.count == 2,
              let microseconds = Double(parts[0]),
              let id = UUID(uuidString: String(parts[1]))
        else { return nil }
        self.timestamp = Date(timeIntervalSince1970: microseconds / 1_000_000)
        self.id = id
    }

    var encoded: String {
        let microseconds = Int((timestamp.timeIntervalSince1970 * 1_000_000).rounded())
        return Data("\(microseconds)|\(id.uuidString)".utf8).base64EncodedString()
    }
}

struct ConversationMembership: Sendable {
    let conversation: ConversationRecord
    let participant: ConversationParticipantRecord
    let otherParticipantIds: [UUID]

    var allParticipantIds: [UUID] { [participant.$user.id] + otherParticipantIds }
}

struct ReadReceipt: Sendable {
    let conversationId: UUID
    let upToMessageId: UUID
    let readAt: Date
    let remainingUnreadCount: Int
}

struct ConversationService: Sendable {
    let database: any Database
    let realtime: RealtimeBroadcaster
    let urls: MediaURLBuilder

    private var messages: MessageProjector {
        MessageProjector(database: database, urls: urls)
    }

    func list(
        for viewer: UUID,
        filter: ConversationFilter,
        page: PageRequest
    ) async throws -> Paginated<Conversation> {
        let query = ConversationParticipantRecord.query(on: database)
            .filter(\.$user.$id == viewer)
            .filter(\.$hasAccepted == (filter == .inbox))
            .join(ConversationRecord.self, on: \ConversationParticipantRecord.$conversation.$id == \ConversationRecord.$id)
            .sort(ConversationRecord.self, \.$updatedAt, .descending)
            .sort(ConversationRecord.self, \.$id, .descending)
        if let cursor = page.cursor.flatMap(MessagingCursor.init(encoded:)) {
            query.group(.or) { group in
                group.filter(ConversationRecord.self, \.$updatedAt < cursor.timestamp)
                group.group(.and) { tie in
                    tie.filter(ConversationRecord.self, \.$updatedAt == cursor.timestamp)
                    tie.filter(ConversationRecord.self, \.$id < cursor.id)
                }
            }
        }

        let rows = try await query.limit(page.limit + 1).all()
        let visible = Array(rows.prefix(page.limit))
        let conversations = try visible.map { try $0.joined(ConversationRecord.self) }
        let items = try await project(conversations, viewedBy: viewer, participantRows: visible)

        var nextCursor: String?
        if rows.count > page.limit, let last = conversations.last, let updatedAt = last.updatedAt {
            nextCursor = MessagingCursor(timestamp: updatedAt, id: try last.requireID()).encoded
        }
        return Paginated(items: items, nextCursor: nextCursor)
    }

    /// Returns the existing conversation for a direct pair rather than a second one. The
    /// unique index on `direct_key` is the arbiter, so two simultaneous opens converge
    /// without a lock: the loser of the race reads the winner's row.
    func create(
        _ body: CreateConversationBody,
        creator: UUID
    ) async throws -> (conversation: Conversation, isNew: Bool) {
        let members = try await validatedMembers(of: body, creator: creator)
        try await requireNoBlock(between: creator, and: members.filter { $0 != creator })

        if members.count == 2 {
            let key = ConversationRecord.directKey(between: members[0], and: members[1])
            if let existing = try await ConversationRecord.query(on: database)
                .filter(\.$directKey == key)
                .first()
            {
                return (try await project(existing, viewedBy: creator), false)
            }
            do {
                let created = try await insert(members: members, creator: creator, directKey: key, title: nil)
                return (try await project(created, viewedBy: creator), true)
            } catch let error as any DatabaseError where error.isConstraintFailure {
                guard let existing = try await ConversationRecord.query(on: database)
                    .filter(\.$directKey == key)
                    .first()
                else { throw APIError.conflict("That conversation could not be opened. Try again.") }
                return (try await project(existing, viewedBy: creator), false)
            }
        }

        let created = try await insert(members: members, creator: creator, directKey: nil, title: body.title)
        return (try await project(created, viewedBy: creator), true)
    }

    func accept(conversationId: UUID, viewer: UUID) async throws -> Conversation {
        let membership = try await requireMembership(of: conversationId, viewer: viewer)
        if !membership.participant.hasAccepted {
            membership.participant.hasAccepted = true
            try await membership.participant.save(on: database)
            await realtime.sendUnreadCounts(to: [viewer], on: database)
        }
        return try await project(membership.conversation, viewedBy: viewer)
    }

    /// Resets `unread_count` by recounting what is still unread past the cursor rather than
    /// subtracting, so a duplicated or out-of-order read receipt cannot leave the counter wrong.
    func markRead(conversationId: UUID, upTo messageId: UUID, viewer: UUID) async throws -> ReadReceipt {
        let membership = try await requireMembership(of: conversationId, viewer: viewer)
        guard let target = try await MessageRecord.find(messageId, on: database),
              target.$conversation.id == conversationId,
              let targetCreatedAt = target.createdAt
        else {
            throw APIError.notFound("That message is not in this conversation.")
        }

        let previousCursor = try await readCursorTimestamp(for: membership.participant)
        try await recordReads(
            in: conversationId,
            by: viewer,
            after: previousCursor,
            through: targetCreatedAt
        )

        let remaining = try await MessageRecord.query(on: database)
            .filter(\.$conversation.$id == conversationId)
            .filter(\.$sender.$id != viewer)
            .filter(\.$createdAt > targetCreatedAt)
            .count()
        let readAt = Date()
        membership.participant.unreadCount = remaining
        let cursorMovesForward = previousCursor.map { $0 <= targetCreatedAt } ?? true
        if cursorMovesForward {
            membership.participant.$lastReadMessage.id = messageId
        }
        try await membership.participant.save(on: database)

        let receipt = ReadReceipt(
            conversationId: conversationId,
            upToMessageId: messageId,
            readAt: readAt,
            remainingUnreadCount: remaining
        )
        await announce(receipt, from: viewer, to: membership.otherParticipantIds)
        return receipt
    }

    func requireMembership(of conversationId: UUID, viewer: UUID) async throws -> ConversationMembership {
        guard let conversation = try await ConversationRecord.find(conversationId, on: database) else {
            throw APIError.notFound("That conversation does not exist.")
        }
        let participants = try await ConversationParticipantRecord.query(on: database)
            .filter(\.$conversation.$id == conversationId)
            .all()
        guard let mine = participants.first(where: { $0.$user.id == viewer }) else {
            throw APIError.notFound("That conversation does not exist.")
        }
        let others = participants.map(\.$user.id).filter { $0 != viewer }
        if conversation.kind == .direct {
            try await requireNoBlock(between: viewer, and: others)
        }
        return ConversationMembership(
            conversation: conversation,
            participant: mine,
            otherParticipantIds: others
        )
    }

    func project(_ conversation: ConversationRecord, viewedBy viewer: UUID) async throws -> Conversation {
        let projected = try await project([conversation], viewedBy: viewer, participantRows: nil)
        guard let first = projected.first else {
            throw APIError.notFound("That conversation does not exist.")
        }
        return first
    }

    private func announce(_ receipt: ReadReceipt, from viewer: UUID, to others: [UUID]) async {
        let payload = MessageReadPayload(
            conversationId: receipt.conversationId,
            userId: viewer,
            upToMessageId: receipt.upToMessageId,
            readAt: receipt.readAt
        )
        await realtime.send(.messageRead(payload), to: others + [viewer])
        await realtime.sendUnreadCounts(to: [viewer], on: database)
    }

    private func readCursorTimestamp(for participant: ConversationParticipantRecord) async throws -> Date? {
        guard let cursorId = participant.$lastReadMessage.id else { return nil }
        return try await MessageRecord.find(cursorId, on: database)?.createdAt
    }

    private func recordReads(
        in conversationId: UUID,
        by viewer: UUID,
        after previousCursor: Date?,
        through targetCreatedAt: Date
    ) async throws {
        let query = MessageRecord.query(on: database)
            .filter(\.$conversation.$id == conversationId)
            .filter(\.$sender.$id != viewer)
            .filter(\.$createdAt <= targetCreatedAt)
        if let previousCursor {
            query.filter(\.$createdAt > previousCursor)
        }
        let messageIds = try await query.limit(500).all().compactMap(\.id)
        guard !messageIds.isEmpty else { return }

        let alreadyRead = Set(
            try await MessageReadRecord.query(on: database)
                .filter(\.$user.$id == viewer)
                .filter(\.$message.$id ~~ messageIds)
                .all()
                .map(\.$message.id)
        )
        let readAt = Date()
        let receipts = messageIds.filter { !alreadyRead.contains($0) }.map { messageId in
            let record = MessageReadRecord()
            record.$message.id = messageId
            record.$user.id = viewer
            record.readAt = readAt
            return record
        }
        guard !receipts.isEmpty else { return }
        do {
            try await receipts.create(on: database)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            return
        }
    }

    private func validatedMembers(
        of body: CreateConversationBody,
        creator: UUID
    ) async throws -> [UUID] {
        var members = Set(body.participantIds)
        members.insert(creator)
        guard members.count >= 2 else {
            throw APIError.validationFailed("A conversation needs at least one other participant.")
        }
        guard members.count <= 50 else {
            throw APIError.validationFailed("A group conversation holds at most 50 people.")
        }
        let existing = try await UserRecord.query(on: database)
            .filter(\.$id ~~ Array(members))
            .filter(\.$isSuspended == false)
            .count()
        guard existing == members.count else {
            throw APIError.validationFailed("One of those accounts does not exist.")
        }
        return members.sorted { $0.uuidString < $1.uuidString }
    }

    private func insert(
        members: [UUID],
        creator: UUID,
        directKey: String?,
        title: String?
    ) async throws -> ConversationRecord {
        let accepted = try await followersAmong(members, of: creator)
        let conversation = ConversationRecord()
        conversation.id = UUID()
        conversation.kind = directKey == nil ? .group : .direct
        conversation.title = title
        conversation.$createdBy.id = creator
        conversation.directKey = directKey

        try await database.transaction { transaction in
            try await conversation.create(on: transaction)
            let conversationId = try conversation.requireID()
            let participants = members.map { member in
                let participant = ConversationParticipantRecord()
                participant.$conversation.id = conversationId
                participant.$user.id = member
                participant.unreadCount = 0
                participant.hasAccepted = member == creator || accepted.contains(member)
                return participant
            }
            try await participants.create(on: transaction)
        }
        return conversation
    }

    /// A conversation is a request for anybody who does not already follow whoever opened it.
    private func followersAmong(_ members: [UUID], of creator: UUID) async throws -> Set<UUID> {
        Set(
            try await FollowRecord.query(on: database)
                .filter(\.$followee.$id == creator)
                .filter(\.$follower.$id ~~ members)
                .all()
                .map(\.$follower.id)
        )
    }

    private func requireNoBlock(between viewer: UUID, and others: [UUID]) async throws {
        guard !others.isEmpty else { return }
        let blocks = try await BlockRecord.query(on: database)
            .group(.or) { group in
                group.group(.and) { outgoing in
                    outgoing.filter(\.$blocker.$id == viewer)
                    outgoing.filter(\.$blocked.$id ~~ others)
                }
                group.group(.and) { incoming in
                    incoming.filter(\.$blocker.$id ~~ others)
                    incoming.filter(\.$blocked.$id == viewer)
                }
            }
            .count()
        guard blocks == 0 else {
            throw APIError.forbidden("You cannot message that person.")
        }
    }

    private func project(
        _ conversations: [ConversationRecord],
        viewedBy viewer: UUID,
        participantRows: [ConversationParticipantRecord]?
    ) async throws -> [Conversation] {
        guard !conversations.isEmpty else { return [] }
        let conversationIds = try conversations.map { try $0.requireID() }
        let everyParticipant = try await ConversationParticipantRecord.query(on: database)
            .filter(\.$conversation.$id ~~ conversationIds)
            .with(\.$user)
            .all()
        let lastMessages = try await messages.project(
            ids: conversations.compactMap { $0.$lastMessage.id }
        )
        let viewerRows = participantRows ?? everyParticipant.filter { $0.$user.id == viewer }

        return try conversations.map { conversation in
            let conversationId = try conversation.requireID()
            let rows = everyParticipant.filter { $0.$conversation.id == conversationId }
            let mine = viewerRows.first {
                $0.$conversation.id == conversationId && $0.$user.id == viewer
            }
            return try conversation.asDTO(
                participants: rows.map(\.user),
                lastMessage: conversation.$lastMessage.id.flatMap { lastMessages[$0] },
                unreadCount: mine?.unreadCount ?? 0,
                isRequest: !(mine?.hasAccepted ?? true),
                urls: urls
            )
        }
    }
}
