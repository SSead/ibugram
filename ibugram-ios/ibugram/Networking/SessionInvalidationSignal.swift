import Foundation
import IBUgramKit

/// Lets the networking layer tell `AuthSessionStore` that refresh failed and the user must
/// sign in again, without either type owning the other.
final class SessionInvalidationSignal: Sendable {
    let events: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        self.events = stream
        self.continuation = continuation
    }

    func invalidate() {
        continuation.yield()
    }
}
