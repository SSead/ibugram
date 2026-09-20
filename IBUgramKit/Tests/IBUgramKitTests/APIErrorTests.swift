import Foundation
import Testing
@testable import IBUgramKit

@Suite("Error envelope")
struct APIErrorTests {
    @Test("The envelope decodes into code, message and details")
    func envelopeDecodes() throws {
        let json = Data(#"""
        { "error": { "code": "otp_invalid", "message": "That code is not correct.", "details": {} } }
        """#.utf8)
        let decoded = try JSONDecoder.ibugram.decode(APIError.self, from: json)
        #expect(decoded.code == .otpInvalid)
        #expect(decoded.message == "That code is not correct.")
        #expect(decoded.details.isEmpty)
    }

    @Test("An omitted details bag decodes as empty rather than failing")
    func detailsAreOptional() throws {
        let json = Data(#"{ "error": { "code": "not_found", "message": "Gone." } }"#.utf8)
        #expect(try JSONDecoder.ibugram.decode(APIError.self, from: json).details.isEmpty)
    }

    @Test("Structured details survive decoding")
    func detailsCarryStructure() throws {
        let json = Data(#"""
        { "error": { "code": "validation_failed", "message": "Bad input.",
          "details": { "username": "too short", "minimum": 3, "retryable": false } } }
        """#.utf8)
        let decoded = try JSONDecoder.ibugram.decode(APIError.self, from: json)
        #expect(decoded.details["username"]?.stringValue == "too short")
        #expect(decoded.details["minimum"]?.intValue == 3)
        #expect(decoded.details["retryable"]?.boolValue == false)
    }

    @Test("An unrecognised code decodes to unknown instead of throwing")
    func unknownCodeFallsBack() throws {
        let json = Data(#"{ "error": { "code": "quota_exhausted", "message": "Nope." } }"#.utf8)
        let decoded = try JSONDecoder.ibugram.decode(APIError.self, from: json)
        #expect(decoded.code == .unknown("quota_exhausted"))
        #expect(decoded.code.isRecognised == false)
        #expect(decoded.code.rawValue == "quota_exhausted")
    }

    @Test("An unknown code re-encodes to the string the server sent")
    func unknownCodeRoundTrips() throws {
        let error = APIError(code: .unknown("teapot"), message: "I am one.")
        let data = try JSONEncoder.ibugram.encode(error)
        let decoded = try JSONDecoder.ibugram.decode(APIError.self, from: data)
        #expect(decoded == error)
        #expect(String(decoding: data, as: UTF8.self).contains(#""code":"teapot""#))
    }

    @Test("Every canonical code in the contract round trips through its wire spelling")
    func canonicalCodesRoundTrip() {
        let expected = [
            "unauthorized", "forbidden", "not_found", "validation_failed", "domain_not_allowed",
            "otp_invalid", "otp_expired", "otp_throttled", "rate_limited", "username_taken",
            "conflict", "payload_too_large", "internal_error"
        ]
        #expect(APIErrorCode.canonical.map(\.rawValue) == expected)
        for raw in expected {
            let code = APIErrorCode(rawValue: raw)
            #expect(code.isRecognised)
            #expect(code.rawValue == raw)
        }
    }

    @Test("Each code carries the status the server answers with")
    func codesMapToStatuses() {
        #expect(APIErrorCode.unauthorized.httpStatus == 401)
        #expect(APIErrorCode.usernameTaken.httpStatus == 409)
        #expect(APIErrorCode.otpThrottled.httpStatus == 429)
        #expect(APIErrorCode.payloadTooLarge.httpStatus == 413)
        #expect(APIErrorCode.unknown("whatever").httpStatus == 500)
    }
}
