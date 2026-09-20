import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SeedImageError: Error {
    case contextFailed
    case encodingFailed
}

enum SeedJPEG {
    static func solid(
        red: Double,
        green: Double,
        blue: Double,
        width: Int,
        height: Int
    ) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw SeedImageError.contextFailed
        }
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw SeedImageError.contextFailed
        }
        return try encode(image)
    }

    private static func encode(_ image: CGImage) throws -> Data {
        let buffer = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            buffer as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw SeedImageError.encodingFailed
        }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.82]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw SeedImageError.encodingFailed
        }
        return buffer as Data
    }
}
