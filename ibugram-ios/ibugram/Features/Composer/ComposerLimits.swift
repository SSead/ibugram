import IBUgramKit
import CoreGraphics

enum ComposerLimits {
    static var maximumImageCount: Int { IBUgram.maxPostMediaCount }
    static let maximumCaptionLength = 2_200
    static let jpegQuality: CGFloat = 0.86
}
