import Foundation

/// Every frame on the socket is `{"type": ..., "payload": ...}`.
public struct WebSocketFrame<Payload: Codable & Sendable & Hashable>: Codable, Sendable, Hashable {
    public var type: String
    public var payload: Payload

    public init(type: String, payload: Payload) {
        self.type = type
        self.payload = payload
    }
}

public struct EmptyPayload: Codable, Sendable, Hashable {
    public init() {}

    public init(from decoder: any Decoder) throws {
        _ = try? decoder.container(keyedBy: FrameCodingKeys.self)
    }

    public func encode(to encoder: any Encoder) throws {
        _ = encoder.container(keyedBy: FrameCodingKeys.self)
    }
}

enum FrameCodingKeys: String, CodingKey {
    case type
    case payload
}

/// Shared decoding for the two discriminated unions below.
enum FrameCoding {
    static func discriminator(from decoder: any Decoder) throws -> String {
        let container = try decoder.container(keyedBy: FrameCodingKeys.self)
        return try container.decode(String.self, forKey: .type)
    }

    static func payload<Payload: Decodable>(
        _ type: Payload.Type,
        from decoder: any Decoder
    ) throws -> Payload {
        let container = try decoder.container(keyedBy: FrameCodingKeys.self)
        return try container.decode(Payload.self, forKey: .payload)
    }

    static func optionalPayload<Payload: Decodable>(
        _ type: Payload.Type,
        from decoder: any Decoder
    ) throws -> Payload? {
        let container = try decoder.container(keyedBy: FrameCodingKeys.self)
        return try container.decodeIfPresent(Payload.self, forKey: .payload)
    }

    static func encode<Payload: Encodable>(
        type: String,
        payload: Payload,
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(keyedBy: FrameCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(payload, forKey: .payload)
    }

    static func unrecognisedType(_ type: String, in decoder: any Decoder) -> DecodingError {
        DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath + [FrameCodingKeys.type],
                debugDescription: "Unrecognised frame type \(type)."
            )
        )
    }
}
