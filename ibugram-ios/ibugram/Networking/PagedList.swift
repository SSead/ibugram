import Foundation
import IBUgramKit

@MainActor
@Observable
final class PagedList<Item: Decodable & Sendable & Identifiable> {
    private(set) var items: [Item] = []
    private(set) var phase: Phase = .idle
    private(set) var isLoadingMore = false
    private(set) var nextCursor: String?
    private(set) var hasReachedEnd = false

    private let loadPage: @Sendable (_ cursor: String?) async throws -> Paginated<Item>

    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(APIError)
    }

    init(loadPage: @escaping @Sendable (_ cursor: String?) async throws -> Paginated<Item>) {
        self.loadPage = loadPage
    }

    var isEmpty: Bool { items.isEmpty && phase == .loaded }

    func loadFirstPageIfNeeded() async {
        guard phase == .idle else { return }
        await reload()
    }

    func reload() async {
        phase = .loading
        do {
            let page = try await loadPage(nil)
            items = page.items
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            phase = .loaded
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func loadNextPage() async {
        guard !isLoadingMore, !hasReachedEnd, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await loadPage(cursor)
            items.append(contentsOf: page.items)
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            hasReachedEnd = false
        }
    }
}
