import Foundation
import IBUgramKit

enum RealtimeFrameError: Error {
    case notUTF8
}

/// `ClientMessage` and `ServerMessage` already carry the contract's `{type, payload}`
/// shape; this is only the string boundary around them.
enum RealtimeFrameCoding {
    static func encode(_ message: ServerMessage) throws -> String {
        let data = try JSONEncoder.ibugram.encode(message)
        guard let text = String(data: data, encoding: .utf8) else {
            throw RealtimeFrameError.notUTF8
        }
        return text
    }

    static func decode(_ text: String) throws -> ClientMessage {
        try JSONDecoder.ibugram.decode(ClientMessage.self, from: Data(text.utf8))
    }
}
