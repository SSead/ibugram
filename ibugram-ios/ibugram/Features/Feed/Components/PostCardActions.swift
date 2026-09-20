import Foundation

struct PostCardActions {
    var onLike: () -> Void = {}
    var onDoubleTapLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onSave: () -> Void = {}
    var onAuthor: () -> Void = {}
    var onHashtag: (String) -> Void = { _ in }
    var onMention: (String) -> Void = { _ in }
    var onLikeCount: () -> Void = {}
    var onDelete: (() -> Void)? = nil
}
