import Foundation
import IBUgramKit

@MainActor
@Observable
final class SpaceBrowseViewModel: ErrorPresenting {
    private(set) var selectedKind: SpaceKind?
    private(set) var spaces: PagedList<Space>
    var presentedError: PresentedError?

    private let api: any APIRequesting

    init(api: any APIRequesting) {
        self.api = api
        spaces = Self.makeList(api: api, kind: nil)
    }

    func load() async {
        await spaces.loadFirstPageIfNeeded()
    }

    func reload() async {
        await spaces.reload()
        if case .failed(let error) = spaces.phase, !spaces.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func selectKind(_ kind: SpaceKind?) async {
        selectedKind = kind
        spaces = Self.makeList(api: api, kind: kind)
        await spaces.loadFirstPageIfNeeded()
    }

    private static func makeList(api: any APIRequesting, kind: SpaceKind?) -> PagedList<Space> {
        PagedList { cursor in
            try await api.send(SpaceEndpoints.Browse(kind: kind, cursor: cursor))
        }
    }
}
