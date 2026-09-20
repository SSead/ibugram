import CoreGraphics
import Foundation
import IBUgramKit
import ImageIO
import Testing
import UniformTypeIdentifiers
import Vapor
import VaporTesting
@testable import App

@Suite("Media upload", .serialized)
struct MediaTests {
    private let uploader = "media.tester@ibu.edu.ba"

    /// A JPEG carrying the metadata a phone camera would attach: a maker string, a GPS fix
    /// and a rotation flag. Anything that survives the upload is a privacy leak.
    private func sourceImage(width: Int = 900, height: Int = 600) throws -> Data {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                pixels[offset] = UInt8(x * 255 / width)
                pixels[offset + 1] = UInt8(y * 255 / height)
                pixels[offset + 2] = 128
                pixels[offset + 3] = 255
            }
        }
        let context = try #require(CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        let image = try #require(context.makeImage())

        let buffer = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            buffer,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ))
        let metadata: [CFString: Any] = [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "IBUGRAM-TEST-CAMERA",
                kCGImagePropertyTIFFModel: "PRIVATE-MODEL-0001"
            ] as [CFString: Any],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 43.8563,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 18.4131,
                kCGImagePropertyGPSLongitudeRef: "E"
            ] as [CFString: Any]
        ]
        CGImageDestinationAddImage(destination, image, metadata as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return buffer as Data
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    private func upload(
        _ context: TestContext,
        image: Data,
        token: String,
        filename: String = "photo.jpg",
        contentType: HTTPMediaType = .jpeg
    ) async throws -> TestingHTTPResponse {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        let boundary = "ibugram-test-boundary"
        body.writeString("--\(boundary)\r\n")
        body.writeString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.writeString("Content-Type: \(contentType.serialize())\r\n\r\n")
        body.writeBytes(image)
        body.writeString("\r\n--\(boundary)--\r\n")

        var headers = context.authorized(token)
        headers.contentType = HTTPMediaType(
            type: "multipart",
            subType: "form-data",
            parameters: ["boundary": boundary]
        )
        return try await context.app.testing().sendRequest(
            .POST,
            API.MediaRoutes.upload.fullPath,
            headers: headers,
            body: body
        )
    }

    @Test("Uploading stores a re-encoded JPEG and a thumbnail")
    func uploadProducesBothRenditions() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: uploader)
            let response = try await upload(context, image: try sourceImage(), token: session.accessToken)
            #expect(response.status == .created)

            let media = try response.content.decode(Media.self)
            #expect(media.width > 0 && media.height > 0)

            let full = try await context.app.testing().sendRequest(
                .GET,
                API.MediaRoutes.download(id: media.id).fullPath
            )
            #expect(full.status == .ok)
            #expect(full.headers.contentType == .jpeg)

            let thumbnail = try await context.app.testing().sendRequest(
                .GET,
                API.MediaRoutes.thumbnail(id: media.id).fullPath
            )
            #expect(thumbnail.status == .ok)

            let fullPixels = try properties(of: Data(buffer: full.body))
            let thumbnailPixels = try properties(of: Data(buffer: thumbnail.body))
            let fullWidth = try #require(fullPixels[kCGImagePropertyPixelWidth] as? Int)
            let thumbnailWidth = try #require(thumbnailPixels[kCGImagePropertyPixelWidth] as? Int)
            #expect(thumbnailWidth < fullWidth)
            #expect(thumbnailWidth <= 200)
        }
    }

    @Test("Camera metadata, GPS and orientation do not survive the upload")
    func metadataIsStripped() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: uploader)
            let original = try sourceImage()

            let originalProperties = try properties(of: original)
            #expect(originalProperties[kCGImagePropertyGPSDictionary] != nil)

            let response = try await upload(context, image: original, token: session.accessToken)
            let media = try response.content.decode(Media.self)
            let stored = try await context.app.testing().sendRequest(
                .GET,
                API.MediaRoutes.download(id: media.id).fullPath
            )
            let bytes = Data(buffer: stored.body)
            let storedProperties = try properties(of: bytes)

            #expect(storedProperties[kCGImagePropertyGPSDictionary] == nil)
            let tiff = storedProperties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            #expect(tiff?[kCGImagePropertyTIFFMake] == nil)
            #expect(tiff?[kCGImagePropertyTIFFModel] == nil)
            #expect((storedProperties[kCGImagePropertyOrientation] as? Int) ?? 1 == 1)
            #expect(!bytes.contains("IBUGRAM-TEST-CAMERA".data(using: .utf8)!))
        }
    }

    @Test("The orientation flag is baked into the pixels instead of being dropped")
    func orientationIsApplied() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: uploader)
            let response = try await upload(
                context,
                image: try sourceImage(width: 900, height: 600),
                token: session.accessToken
            )
            let media = try response.content.decode(Media.self)
            #expect(media.height > media.width)
        }
    }

    @Test("A non-image upload is rejected as a validation failure")
    func garbageIsRejected() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: uploader)
            let response = try await upload(
                context,
                image: Data("this is not an image".utf8),
                token: session.accessToken
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }

    @Test("An unsupported content type is refused before decoding")
    func unsupportedContentTypeIsRefused() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: uploader)
            let response = try await upload(
                context,
                image: try sourceImage(),
                token: session.accessToken,
                filename: "photo.gif",
                contentType: HTTPMediaType(type: "image", subType: "gif")
            )
            #expect(response.status == .unprocessableEntity)
        }
    }

    @Test("Uploading needs a bearer token")
    func uploadRequiresAuthentication() async throws {
        try await withTestServer { context in
            let response = try await upload(context, image: try sourceImage(), token: "nonsense")
            #expect(response.status == .unauthorized)
        }
    }

    @Test("An unknown media id is a structured 404")
    func missingMediaIsNotFound() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(
                .GET,
                API.MediaRoutes.download(id: UUID()).fullPath
            )
            #expect(response.status == .notFound)
            #expect(response.apiError?.code == .notFound)
        }
    }
}
