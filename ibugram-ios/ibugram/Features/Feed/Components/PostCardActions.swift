import Foundation
import IBUgramKit

struct PostCardActions {
    var onLike: () -> Void = {}
    var onDoubleTapLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onSave: () -> Void = {}
    var onAuthor: () -> Void = {}
    var onHashtag: (String) -> Void = { _ in }
    var onMention: (String) -> Void = { _ in }
    var onLikeCount: () -> Void = {}
    var onSpace: (SpaceSummary) -> Void = { _ in }
    var onEvent: (Event) -> Void = { _ in }
    var onLocation: (Place) -> Void = { _ in }
    var onDelete: (() -> Void)? = nil
}
