import Foundation
import IBUgramKit

@MainActor
@Observable
final class SpaceMembersViewModel: ErrorPresenting {
    let members: PagedList<SpaceMember>
    var presentedError: PresentedError?

    init(api: any APIRequesting, slug: String) {
        members = PagedList { cursor in
            try await api.send(SpaceEndpoints.Members(slug: slug, cursor: cursor))
        }
    }

    func load() async {
        await members.loadFirstPageIfNeeded()
    }

    func reload() async {
        await members.reload()
        if case .failed(let error) = members.phase, !members.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }
}
