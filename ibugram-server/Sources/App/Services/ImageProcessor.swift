import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ProcessedImage: Sendable {
    let jpeg: Data
    let thumbnail: Data
    let width: Int
    let height: Int
}

enum ImageProcessingError: Error {
    case unreadable
    case unsupportedFormat(String)
    case encodingFailed
}

/// Decoding through ImageIO and re-encoding from the bare `CGImage` is what strips EXIF:
/// nothing is carried across from the source container, including GPS tags.
struct ImageProcessor: Sendable {
    static let acceptedContentTypes: Set<String> = [
        "image/jpeg", "image/png", "image/heic", "image/heif"
    ]

    let maximumPixelSize: Int
    let thumbnailPixelSize: Int
    let compressionQuality: Double

    init(maximumPixelSize: Int = 2048, thumbnailPixelSize: Int, compressionQuality: Double) {
        self.maximumPixelSize = maximumPixelSize
        self.thumbnailPixelSize = thumbnailPixelSize
        self.compressionQuality = compressionQuality
    }

    func process(_ data: Data) throws -> ProcessedImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw ImageProcessingError.unreadable
        }
        let full = try image(from: source, maximumPixelSize: maximumPixelSize)
        let small = try image(from: source, maximumPixelSize: thumbnailPixelSize)
        return ProcessedImage(
            jpeg: try encodeJPEG(full),
            thumbnail: try encodeJPEG(small),
            width: full.width,
            height: full.height
        )
    }

    /// `kCGImageSourceCreateThumbnailWithTransform` applies the source orientation, so the
    /// stored pixels are upright once the EXIF tag is gone.
    private func image(from source: CGImageSource, maximumPixelSize: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageProcessingError.unreadable
        }
        return image
    }

    private func encodeJPEG(_ image: CGImage) throws -> Data {
        let buffer = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            buffer as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageProcessingError.encodingFailed
        }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessingError.encodingFailed
        }
        return buffer as Data
    }
}
