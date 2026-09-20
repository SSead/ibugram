import CryptoKit
import Foundation

enum SeedIdentity {
    static func uuid(_ name: String) -> UUID {
        let digest = SHA256.hash(data: Data("ibugram.seed.\(name)".utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func mediaKeys(for id: UUID) -> (full: String, thumbnail: String) {
        let prefix = id.uuidString.prefix(2).lowercased()
        return (
            full: "\(prefix)/\(id.uuidString).jpg",
            thumbnail: "\(prefix)/\(id.uuidString)-thumb.jpg"
        )
    }
}
