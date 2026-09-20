import Foundation
import Testing

@testable import ibugram

@Suite("Email domain validation")
struct EmailDomainValidatorTests {
    @Test("a student address is allowed and resolves to the student role")
    func studentAddressIsAllowed() {
        #expect(EmailDomainValidator.verdict(for: "amina.hodzic@stu.ibu.edu.ba") == .allowed(role: .student))
    }

    @Test("a staff address is allowed and resolves to the faculty role")
    func facultyAddressIsAllowed() {
        #expect(EmailDomainValidator.verdict(for: "d.kovac@ibu.edu.ba") == .allowed(role: .faculty))
    }

    @Test("an address outside the university is rejected with the offending domain")
    func outsideDomainIsRejected() {
        #expect(EmailDomainValidator.verdict(for: "someone@gmail.com") == .domainNotAllowed("gmail.com"))
    }

    @Test("surrounding whitespace and capitals do not change the verdict")
    func inputIsNormalizedBeforeValidation() {
        #expect(EmailDomainValidator.verdict(for: "  Amina@STU.IBU.EDU.BA ").isAllowed)
    }

    @Test("an address without an at sign is malformed")
    func addressWithoutAtSignIsMalformed() {
        #expect(EmailDomainValidator.verdict(for: "amina.ibu.edu.ba") == .malformed)
    }

    @Test("an empty field is neither valid nor an error")
    func emptyAddressIsEmpty() {
        #expect(EmailDomainValidator.verdict(for: "   ") == .empty)
    }
}

@Suite("Error envelope mapping")
struct APIErrorMappingTests {
    @Test("a documented error code maps to its typed case")
    func documentedCodeMapsToTypedCase() throws {
        let json = Data(#"{"error":{"code":"otp_expired","message":"That code has expired."}}"#.utf8)
        let envelope = try JSONDecoder.ibugram.decode(APIErrorEnvelope.self, from: json)
        #expect(APIError(envelope: envelope, statusCode: 400, retryAfter: nil) == .otpExpired)
    }

    @Test("a throttle response carries the Retry-After hint")
    func throttleCarriesRetryAfter() throws {
        let json = Data(#"{"error":{"code":"otp_throttled","message":"Too many requests."}}"#.utf8)
        let envelope = try JSONDecoder.ibugram.decode(APIErrorEnvelope.self, from: json)
        #expect(APIError(envelope: envelope, statusCode: 429, retryAfter: 42) == .otpThrottled(retryAfter: 42))
    }

    @Test("an unknown code degrades to a server error rather than crashing")
    func unknownCodeDegradesToServerError() throws {
        let json = Data(#"{"error":{"code":"teapot","message":"I am a teapot."}}"#.utf8)
        let envelope = try JSONDecoder.ibugram.decode(APIErrorEnvelope.self, from: json)
        #expect(
            APIError(envelope: envelope, statusCode: 418, retryAfter: nil)
                == .server(status: 418, code: "teapot", message: "I am a teapot.")
        )
    }

    @Test("the server message is never surfaced verbatim for a documented code")
    func documentedCodeUsesLocalCopy() {
        #expect(APIError.domainNotAllowed.userFacingDescription.contains("ibu.edu.ba"))
    }
}

@Suite("Contract decoding")
struct ContractDecodingTests {
    @Test("snake_case keys and fractional-second timestamps decode into the DTOs")
    func userDecodesFromContractShape() throws {
        let json = Data(
            #"""
            {
              "id": "11111111-1111-4111-8111-111111111111",
              "username": "amina.h",
              "display_name": "Amina Hodžić",
              "avatar_url": null,
              "bio": null,
              "role": "student",
              "department": "Information Technologies",
              "year_of_study": 4,
              "is_verified": false,
              "counts": { "posts": 42, "followers": 618, "following": 214 },
              "viewer": { "is_following": true, "is_followed_by": false, "is_blocked": false },
              "created_at": "2026-09-20T07:31:12.482Z"
            }
            """#.utf8
        )
        let user = try JSONDecoder.ibugram.decode(User.self, from: json)
        #expect(user.username == "amina.h")
        #expect(user.counts.followers == 618)
        #expect(user.viewer?.isFollowing == true)
    }

    @Test("a cursor page exposes its continuation token")
    func pageDecodesNextCursor() throws {
        let json = Data(#"{"items":[],"next_cursor":"opaque-cursor"}"#.utf8)
        let page = try JSONDecoder.ibugram.decode(Page<User>.self, from: json)
        #expect(page.nextCursor == "opaque-cursor")
        #expect(page.items.isEmpty)
    }
}

@Suite("Token storage")
struct TokenStoreTests {
    @Test("an expiry is derived from the session's expires_in")
    func expiryIsDerivedFromSession() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let pair = TokenPair(session: SampleData.session, now: now)
        #expect(pair.accessTokenExpiresAt == now.addingTimeInterval(900))
        #expect(pair.refreshToken == SampleData.session.refreshToken)
    }

    @Test("clearing the store removes the tokens")
    func clearingRemovesTokens() async throws {
        let store = InMemoryTokenStore(tokens: SampleData.tokens)
        try await store.clear()
        #expect(await store.currentTokens() == nil)
    }
}

@Suite("Reconnection backoff")
struct WebSocketBackoffTests {
    @Test("the first attempt waits about a second and growth is capped at thirty")
    func backoffStaysWithinContractBounds() {
        let first = WebSocketClient.backoffDelay(forAttempt: 0)
        let late = WebSocketClient.backoffDelay(forAttempt: 12)
        #expect(first >= .seconds(1) && first <= .seconds(2))
        #expect(late <= .seconds(30))
    }
}

@Suite("Mock API client")
struct MockAPIClientTests {
    @Test("an unstubbed endpoint fails loudly so previews cannot silently pass")
    func unstubbedEndpointThrows() async {
        let client = MockAPIClient(stubs: [:])
        await #expect(throws: APIError.notFound) {
            _ = try await client.send(UserEndpoint.me())
        }
    }

    @Test("a stubbed endpoint returns its fixture")
    func stubbedEndpointReturnsFixture() async throws {
        let client = MockAPIClient()
        let user = try await client.send(UserEndpoint.me())
        #expect(user.username == SampleData.amina.username)
    }
}

@Suite("Blurhash placeholders")
struct BlurHashTests {
    @Test("a valid hash decodes to an image of the requested size")
    func validHashDecodes() {
        let image = BlurHash.image(from: "LEHV6nWB2yk8pyo0adR*.7kCMdnj", size: CGSize(width: 16, height: 16))
        #expect(image?.size == CGSize(width: 16, height: 16))
    }

    @Test("a malformed hash returns nothing instead of trapping")
    func malformedHashReturnsNil() {
        #expect(BlurHash.image(from: "nope") == nil)
    }
}
