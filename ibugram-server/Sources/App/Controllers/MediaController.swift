import Fluent
import Foundation
import IBUgramKit
import Vapor

struct MediaController: RouteCollection {
    private struct Upload: Content {
        enum CodingKeys: String, CodingKey {
            case file
            case altText = "alt_text"
        }

        var file: File
        var altText: String?
    }

    func boot(routes: any RoutesBuilder) throws {
        routes.grouped(AccessTokenAuthenticator())
            .on(API.MediaRoutes.upload, body: .collect(maxSize: "12mb"), use: upload)
        routes.on(API.MediaRoutes.downloadTemplate, use: download)
        routes.on(API.MediaRoutes.thumbnailTemplate, use: downloadThumbnail)
    }

    private func upload(_ request: Request) async throws -> Response {
        let uploader = try request.requireCurrentUserRecord()
        let submission = try request.content.decode(Upload.self)
        let bytes = Data(buffer: submission.file.data)

        guard bytes.count <= request.configuration.maxUploadBytes else {
            throw APIError(code: .payloadTooLarge, message: "Images must be 10 MB or smaller.")
        }
        if let declaredType = submission.file.contentType?.serialize().lowercased(),
           !ImageProcessor.acceptedContentTypes.contains(declaredType.components(separatedBy: ";")[0]) {
            throw APIError.validationFailed(
                "Upload a JPEG, PNG or HEIC image.",
                details: ["content_type": .string(declaredType)]
            )
        }

        let processed: ProcessedImage
        do {
            processed = try request.dependencies.imageProcessor.process(bytes)
        } catch {
            throw APIError.validationFailed("That file could not be read as an image.")
        }

        let identifier = UUID()
        let keys = Self.storageKeys(for: identifier)
        try await request.dependencies.mediaStore.write(processed.jpeg, to: keys.full)
        try await request.dependencies.mediaStore.write(processed.thumbnail, to: keys.thumbnail)

        let record = MediaRecord(
            id: identifier,
            uploadedById: try uploader.requireID(),
            storageKey: keys.full,
            thumbnailStorageKey: keys.thumbnail,
            contentType: "image/jpeg",
            byteSize: processed.jpeg.count,
            width: processed.width,
            height: processed.height,
            altText: submission.altText
        )
        try await record.create(on: request.db)
        return try Response.json(try record.asDTO(urls: request.dependencies.urls), status: .created)
    }

    private func download(_ request: Request) async throws -> Response {
        try await serve(request) { $0.storageKey }
    }

    private func downloadThumbnail(_ request: Request) async throws -> Response {
        try await serve(request) { $0.thumbnailStorageKey }
    }

    private func serve(_ request: Request, key: (MediaRecord) -> String) async throws -> Response {
        guard let identifier = request.parameters.get("id", as: UUID.self),
              let record = try await MediaRecord.find(identifier, on: request.db)
        else {
            throw APIError.notFound("That image does not exist.")
        }
        let bytes: Data
        do {
            bytes = try await request.dependencies.mediaStore.read(key(record))
        } catch {
            throw APIError.notFound("That image is no longer stored.")
        }
        let response = Response(status: .ok, body: .init(data: bytes))
        response.headers.contentType = HTTPMediaType(type: "image", subType: "jpeg")
        response.headers.cacheControl = HTTPHeaders.CacheControl(isPublic: true, maxAge: 31_536_000)
        return response
    }

    private static func storageKeys(for identifier: UUID) -> (full: String, thumbnail: String) {
        let prefix = identifier.uuidString.prefix(2).lowercased()
        return (
            full: "\(prefix)/\(identifier.uuidString).jpg",
            thumbnail: "\(prefix)/\(identifier.uuidString)-thumb.jpg"
        )
    }
}
