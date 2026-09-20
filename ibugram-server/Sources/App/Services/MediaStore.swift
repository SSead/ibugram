import Foundation
import Vapor

protocol MediaStore: Sendable {
    func write(_ data: Data, to key: String) async throws
    func read(_ key: String) async throws -> Data
    func remove(_ key: String) async throws
}

enum MediaStoreError: Error {
    case notFound(String)
}

struct FileSystemMediaStore: MediaStore {
    let root: URL

    init(root: URL) throws {
        self.root = root
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func write(_ data: Data, to key: String) async throws {
        let destination = try location(for: key)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: destination, options: .atomic)
    }

    func read(_ key: String) async throws -> Data {
        let source = try location(for: key)
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw MediaStoreError.notFound(key)
        }
        return try Data(contentsOf: source)
    }

    func remove(_ key: String) async throws {
        let target = try location(for: key)
        guard FileManager.default.fileExists(atPath: target.path) else { return }
        try FileManager.default.removeItem(at: target)
    }

    /// Keys come from the database, never from a request, but a traversal check keeps a
    /// future caller from turning the store into an arbitrary file reader.
    private func location(for key: String) throws -> URL {
        guard !key.contains(".."), !key.hasPrefix("/") else {
            throw MediaStoreError.notFound(key)
        }
        return root.appendingPathComponent(key)
    }
}
