import Foundation

@MainActor
@Observable
final class PostDetailViewModel: ErrorPresenting {
    var presentedError: PresentedError?
    var draft = ""
    var replyingTo: Comment?
    private(set) var post: Post?
    private(set) var currentUser: User?
    private(set) var comments: [Comment] = []
    private(set) var phase: Phase = .loading
    private(set) var isSendingComment = false
    private(set) var isLoadingMoreComments = false

    private let api: any APIRequesting
    private let postID: UUID
    private let commentsPage: Paginated<Comment>
    private var commentEngagement: [UUID: CommentEngagement] = [:]
    private var inFlightCommentLikes: Set<UUID> = []

    enum Phase: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    init(api: any APIRequesting, postID: UUID) {
        self.api = api
        self.postID = postID
        self.commentsPage = Paginated { cursor in
            try await api.send(PostEndpoint.comments(postID: postID, cursor: cursor))
        }
    }

    var isInitialLoading: Bool { phase == .loading && post == nil }
    var commentsFailed: APIError? {
        if case .failed(let error) = commentsPage.phase { error } else { nil }
    }

    var threadedComments: [ThreadedComment] {
        let resolvedComments = comments.map(resolved)
        let replies = Dictionary(grouping: resolvedComments.filter(\.isReply), by: { $0.parentId ?? $0.id })
        return resolvedComments
            .filter { !$0.isReply }
            .map { ThreadedComment(comment: $0, replies: replies[$0.id] ?? []) }
    }

    var commentsAreEmpty: Bool {
        comments.isEmpty && commentsPage.phase == .loaded
    }

    func load() async {
        if post == nil { phase = .loading }
        do {
            async let loadedPost = api.send(PostEndpoint.detail(postID: postID))
            async let loadedMe = api.send(UserEndpoint.me())
            await commentsPage.loadFirstPageIfNeeded()
            post = try await loadedPost
            currentUser = try? await loadedMe
            comments = commentsPage.items
            phase = .loaded
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func reload() async {
        await commentsPage.reload()
        comments = commentsPage.items
        do {
            post = try await api.send(PostEndpoint.detail(postID: postID))
            phase = .loaded
        } catch {
            if post == nil {
                phase = .failed(error.asAPIError)
            } else {
                present(error) { [weak self] in await self?.reload() }
            }
        }
    }

    func loadMoreComments() async {
        let known = Set(comments.map(\.id))
        isLoadingMoreComments = true
        defer { isLoadingMoreComments = false }
        await commentsPage.loadNextPage()
        comments.append(contentsOf: commentsPage.items.filter { !known.contains($0.id) })
    }

    func toggleLike() async {
        guard let post else { return }
        let liked = !post.hasLiked
        self.post = post.applyingEngagement(
            hasLiked: liked,
            hasSaved: post.hasSaved,
            likeCount: post.counts.likes + (liked ? 1 : -1)
        )
        do {
            if liked {
                _ = try await api.send(PostEndpoint.like(postID: post.id))
            } else {
                _ = try await api.send(PostEndpoint.unlike(postID: post.id))
            }
        } catch {
            self.post = post
            present(error) { [weak self] in await self?.toggleLike() }
        }
    }

    func likeIfNeeded() async {
        guard let post, !post.hasLiked else { return }
        await toggleLike()
    }

    func toggleSave() async {
        guard let post else { return }
        let saved = !post.hasSaved
        self.post = post.applyingEngagement(hasLiked: post.hasLiked, hasSaved: saved, likeCount: post.counts.likes)
        do {
            if saved {
                _ = try await api.send(PostEndpoint.save(postID: post.id))
            } else {
                _ = try await api.send(PostEndpoint.unsave(postID: post.id))
            }
        } catch {
            self.post = post
            present(error) { [weak self] in await self?.toggleSave() }
        }
    }

    func sendComment() async {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let author = currentUser, post?.commentsEnabled != false else { return }
        isSendingComment = true
        defer { isSendingComment = false }
        let parentID = replyingTo?.id
        let optimistic = Comment(
            id: UUID(),
            postId: postID,
            author: author,
            body: body,
            parentId: parentID,
            replyCount: 0,
            likeCount: 0,
            viewer: CommentViewerState(hasLiked: false),
            createdAt: .now
        )
        comments.append(optimistic)
        draft = ""
        let replied = replyingTo
        replyingTo = nil
        do {
            let created = try await api.send(PostEndpoint.createComment(postID: postID, body: body, parentID: parentID))
            if let index = comments.firstIndex(where: { $0.id == optimistic.id }) {
                comments[index] = created
            }
            bumpCommentCount(by: 1)
        } catch {
            comments.removeAll { $0.id == optimistic.id }
            draft = body
            replyingTo = replied
            present(error) { [weak self] in await self?.sendComment() }
        }
    }

    func toggleLike(on comment: Comment) async {
        guard !inFlightCommentLikes.contains(comment.id) else { return }
        let current = commentEngagement[comment.id] ?? CommentEngagement(hasLiked: comment.hasLiked, likeCount: comment.likeCount)
        let liked = !current.hasLiked
        commentEngagement[comment.id] = CommentEngagement(
            hasLiked: liked,
            likeCount: max(0, current.likeCount + (liked ? 1 : -1))
        )
        inFlightCommentLikes.insert(comment.id)
        defer { inFlightCommentLikes.remove(comment.id) }
        do {
            if liked {
                _ = try await api.send(PostEndpoint.likeComment(commentID: comment.id))
            } else {
                _ = try await api.send(PostEndpoint.unlikeComment(commentID: comment.id))
            }
        } catch {
            commentEngagement[comment.id] = current
            present(error) { [weak self] in await self?.toggleLike(on: comment) }
        }
    }

    func delete(_ comment: Comment) async {
        guard canDelete(comment) else { return }
        comments.removeAll { $0.id == comment.id || $0.parentId == comment.id }
        do {
            _ = try await api.send(PostEndpoint.deleteComment(commentID: comment.id))
            bumpCommentCount(by: -1)
        } catch {
            await commentsPage.reload()
            comments = commentsPage.items
            present(error) { [weak self] in await self?.delete(comment) }
        }
    }

    func canDelete(_ comment: Comment) -> Bool {
        comment.author.id == currentUser?.id
    }

    func beginReply(to comment: Comment) {
        if comment.isReply {
            replyingTo = comments.first(where: { $0.id == comment.parentId }) ?? comment
        } else {
            replyingTo = comment
        }
    }

    func cancelReply() {
        replyingTo = nil
    }

    private func resolved(_ comment: Comment) -> Comment {
        guard let overlay = commentEngagement[comment.id] else { return comment }
        return comment.applyingLike(hasLiked: overlay.hasLiked, likeCount: overlay.likeCount)
    }

    private func bumpCommentCount(by delta: Int) {
        guard let post else { return }
        self.post = post.applyingEngagement(
            hasLiked: post.hasLiked,
            hasSaved: post.hasSaved,
            likeCount: post.counts.likes,
            commentCount: post.counts.comments + delta
        )
    }
}

struct CommentEngagement: Equatable, Sendable {
    var hasLiked: Bool
    var likeCount: Int
}
