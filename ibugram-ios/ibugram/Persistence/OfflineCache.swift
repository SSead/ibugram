import Foundation

/// The read-through cache seam. The Offline-first team replaces the implementation with
/// SwiftData-backed storage plus the outbox; the protocol is what callers depend on.
protocol OfflineCaching: Sendable {
    func value<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T?
    func store<T: Encodable & Sendable>(_ value: T, forKey key: String) async
    func removeValue(forKey key: String) async
    func removeAll() async
}

actor FileSystemOfflineCache: OfflineCaching {
    private let directory: URL
    private let decoder = JSONDecoder.ibugram
    private let encoder = JSONEncoder.ibugram

    init(directoryName: String = "OfflineCache") {
        let caches = URL.cachesDirectory.appending(path: directoryName, directoryHint: .isDirectory)
        directory = caches
        try? FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
    }

    func value<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = try? Data(contentsOf: fileURL(forKey: key)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func store<T: Encodable & Sendable>(_ value: T, forKey key: String) async {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL(forKey: key), options: .atomic)
    }

    func removeValue(forKey key: String) async {
        try? FileManager.default.removeItem(at: fileURL(forKey: key))
    }

    func removeAll() async {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(forKey key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return directory.appending(path: "\(safeKey).json", directoryHint: .notDirectory)
    }
}

struct NullOfflineCache: OfflineCaching {
    func value<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async -> T? { nil }
    func store<T: Encodable & Sendable>(_ value: T, forKey key: String) async {}
    func removeValue(forKey key: String) async {}
    func removeAll() async {}
}
