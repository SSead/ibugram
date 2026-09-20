import CoreGraphics
import Foundation
import UIKit

/// Decoder for the compact BlurHash placeholders the media pipeline attaches to every `Media`.
/// Implements the reference algorithm (base-83 payload, inverse DCT over `numX * numY` components).
enum BlurHash {
    static func image(from hash: String, size: CGSize = CGSize(width: 32, height: 32), punch: Float = 1) -> UIImage? {
        let characters = Array(hash)
        guard characters.count >= 6,
              let sizeFlag = decode83(characters[0...0]),
              let quantisedMaximum = decode83(characters[1...1]) else { return nil }

        let componentsX = sizeFlag % 9 + 1
        let componentsY = sizeFlag / 9 + 1
        guard characters.count == 4 + 2 * componentsX * componentsY,
              let dc = decode83(characters[2..<6]) else { return nil }

        let maximumValue = Float(quantisedMaximum + 1) / 166 * punch
        var components: [(r: Float, g: Float, b: Float)] = [decodeDC(dc)]
        for index in 1..<(componentsX * componentsY) {
            let start = 4 + index * 2
            guard let value = decode83(characters[start..<(start + 2)]) else { return nil }
            components.append(decodeAC(value, maximumValue: maximumValue))
        }
        return render(components: components, componentsX: componentsX, componentsY: componentsY, size: size)
    }

    private static func render(
        components: [(r: Float, g: Float, b: Float)],
        componentsX: Int,
        componentsY: Int,
        size: CGSize
    ) -> UIImage? {
        let width = max(1, Int(size.width))
        let height = max(1, Int(size.height))
        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                var red: Float = 0
                var green: Float = 0
                var blue: Float = 0
                for j in 0..<componentsY {
                    for i in 0..<componentsX {
                        let basis = cos(Float.pi * Float(x) * Float(i) / Float(width))
                            * cos(Float.pi * Float(y) * Float(j) / Float(height))
                        let component = components[i + j * componentsX]
                        red += component.r * basis
                        green += component.g * basis
                        blue += component.b * basis
                    }
                }
                let offset = (y * width + x) * 4
                pixels[offset] = linearToSRGB(red)
                pixels[offset + 1] = linearToSRGB(green)
                pixels[offset + 2] = linearToSRGB(blue)
            }
        }
        return makeImage(from: pixels, width: width, height: height)
    }

    private static func makeImage(from pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static let alphabet = Array(
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"
    )

    private static func decode83(_ characters: ArraySlice<Character>) -> Int? {
        var value = 0
        for character in characters {
            guard let index = alphabet.firstIndex(of: character) else { return nil }
            value = value * 83 + index
        }
        return value
    }

    private static func decodeDC(_ value: Int) -> (r: Float, g: Float, b: Float) {
        (sRGBToLinear(value >> 16), sRGBToLinear((value >> 8) & 255), sRGBToLinear(value & 255))
    }

    private static func decodeAC(_ value: Int, maximumValue: Float) -> (r: Float, g: Float, b: Float) {
        let quantisedR = value / (19 * 19)
        let quantisedG = (value / 19) % 19
        let quantisedB = value % 19
        return (
            signedPow((Float(quantisedR) - 9) / 9) * maximumValue,
            signedPow((Float(quantisedG) - 9) / 9) * maximumValue,
            signedPow((Float(quantisedB) - 9) / 9) * maximumValue
        )
    }

    private static func signedPow(_ value: Float) -> Float {
        (value < 0 ? -1 : 1) * value * value
    }

    private static func sRGBToLinear(_ value: Int) -> Float {
        let normalized = Float(value) / 255
        return normalized <= 0.04045
            ? normalized / 12.92
            : pow((normalized + 0.055) / 1.055, 2.4)
    }

    private static func linearToSRGB(_ value: Float) -> UInt8 {
        let clamped = min(max(value, 0), 1)
        let encoded = clamped <= 0.0031308
            ? clamped * 12.92
            : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        return UInt8(min(max(encoded * 255 + 0.5, 0), 255))
    }
}
