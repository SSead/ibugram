import Foundation
import Testing
@testable import IBUgramKit

private func roundTrip<Value: Codable & Equatable>(_ value: Value) throws -> Value {
    let data = try JSONEncoder.ibugram.encode(value)
    return try JSONDecoder.ibugram.decode(Value.self, from: data)
}

private func wireObject(_ value: some Encodable) throws -> [String: Any] {
    let data = try JSONEncoder.ibugram.encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    return object as? [String: Any] ?? [:]
}

@Suite("DTO coding")
struct DTOCodingTests {
    @Test("A user survives a coding round trip unchanged")
    func userRoundTrips() throws {
        #expect(try roundTrip(Fixture.student) == Fixture.student)
    }

    @Test("A fully populated post survives a coding round trip unchanged")
    func postRoundTrips() throws {
        #expect(try roundTrip(Fixture.post) == Fixture.post)
    }

    @Test("Every remaining core resource survives a coding round trip unchanged")
    func coreResourcesRoundTrip() throws {
        #expect(try roundTrip(Fixture.media) == Fixture.media)
        #expect(try roundTrip(Fixture.comment) == Fixture.comment)
        #expect(try roundTrip(Fixture.space) == Fixture.space)
        #expect(try roundTrip(Fixture.spaceSummary) == Fixture.spaceSummary)
        #expect(try roundTrip(Fixture.place) == Fixture.place)
        #expect(try roundTrip(Fixture.event) == Fixture.event)
        #expect(try roundTrip(Fixture.conversation) == Fixture.conversation)
        #expect(try roundTrip(Fixture.message) == Fixture.message)
        #expect(try roundTrip(Fixture.notification) == Fixture.notification)
        #expect(try roundTrip(Fixture.authSession) == Fixture.authSession)
    }

    @Test("Request bodies survive a coding round trip unchanged")
    func requestBodiesRoundTrip() throws {
        let create = CreatePostBody(
            mediaIds: [Fixture.mediaId],
            caption: "Hello #burch",
            spaceId: Fixture.spaceId,
            event: PostEventInput(id: Fixture.eventId),
            place: PlaceInput(name: "Library", latitude: 43.8, longitude: 18.3, isCampusLocation: true),
            commentsEnabled: false
        )
        #expect(try roundTrip(create) == create)

        let verify = VerifyCodeBody(email: "amina@stu.ibu.edu.ba", code: "123456", deviceName: "iPhone 17")
        #expect(try roundTrip(verify) == verify)

        let message = CreateMessageBody(body: "hi", mediaIds: nil, clientId: Fixture.messageId)
        #expect(try roundTrip(message) == message)
    }

    @Test("A paginated envelope keeps its items and cursor")
    func paginatedRoundTrips() throws {
        let page = Paginated(items: [Fixture.post], nextCursor: "b3B0aW9u")
        let decoded = try roundTrip(page)
        #expect(decoded == page)
        #expect(decoded.hasMore)
        #expect(Paginated(items: [Fixture.post]).hasMore == false)
    }
}

@Suite("Wire format")
struct WireFormatTests {
    @Test("Multi-word properties are written as snake_case")
    func propertiesUseSnakeCase() throws {
        let object = try wireObject(Fixture.student)
        #expect(object["display_name"] as? String == "Amina Hodžić")
        #expect(object["avatar_url"] != nil)
        #expect(object["year_of_study"] as? Int == 3)
        #expect(object["is_verified"] as? Bool == false)
        #expect(object["created_at"] != nil)
        #expect(object["displayName"] == nil)

        let viewer = object["viewer"] as? [String: Any]
        #expect(viewer?["is_following"] as? Bool == true)
        #expect(viewer?["is_followed_by"] as? Bool == false)
    }

    @Test("A paginated envelope is written as items and next_cursor")
    func pageUsesContractKeys() throws {
        let object = try wireObject(Paginated(items: [Fixture.media], nextCursor: "abc"))
        #expect(object["items"] is [Any])
        #expect(object["next_cursor"] as? String == "abc")
    }

    @Test("Timestamps are ISO-8601 UTC with fractional seconds")
    func timestampsIncludeFractionalSeconds() throws {
        let object = try wireObject(Fixture.student)
        #expect(object["created_at"] as? String == Fixture.timestampText)
    }

    @Test("Timestamps without a fractional part still decode")
    func wholeSecondTimestampsDecode() throws {
        let json = Data(#"{"expires_at":"2026-09-20T07:31:12Z","resend_after":60}"#.utf8)
        let decoded = try JSONDecoder.ibugram.decode(RequestCodeResponse.self, from: json)
        #expect(IBUgramDateCoding.string(from: decoded.expiresAt) == "2026-09-20T07:31:12.000Z")
        #expect(decoded.debugCode == nil)
    }

    @Test("A timestamp that is not ISO-8601 is rejected")
    func malformedTimestampFails() {
        let json = Data(#"{"expires_at":"yesterday","resend_after":60}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder.ibugram.decode(RequestCodeResponse.self, from: json)
        }
    }

    @Test("Role and enum values are written as the contract's lowercase strings")
    func enumsUseContractSpelling() throws {
        #expect(try wireObject(Fixture.student)["role"] as? String == "student")
        #expect(try wireObject(Fixture.faculty)["role"] as? String == "faculty")
        #expect(try wireObject(Fixture.notification)["kind"] as? String == "like")
        #expect(NotificationKind.spaceInvite.rawValue == "space_invite")
        #expect(NotificationKind.eventReminder.rawValue == "event_reminder")
    }
}
