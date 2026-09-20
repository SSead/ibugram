import Foundation
import IBUgramKit
import MapKit

@MainActor
@Observable
final class CampusMapViewModel: ErrorPresenting {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(APIError)
    }

    private(set) var phase: Phase = .idle
    private(set) var contents = MapContents()
    var presentedError: PresentedError?

    private let api: any APIRequesting
    private var lastQuery: String?

    init(api: any APIRequesting) {
        self.api = api
    }

    var pins: [CampusMapPin] { CampusMapPin.pins(from: contents) }

    func load(region: MKCoordinateRegion) async {
        guard let bbox = MapBoundingBox.from(region: region) else { return }
        let query = bbox.queryValue
        if query == lastQuery, phase == .loaded { return }
        lastQuery = query
        phase = contents.events.isEmpty && contents.posts.isEmpty ? .loading : phase
        do {
            contents = try await api.send(EventEndpoints.Map(bbox: bbox))
            phase = .loaded
        } catch {
            let apiError = error.asAPIError
            if contents.events.isEmpty && contents.posts.isEmpty {
                phase = .failed(apiError)
            } else {
                present(apiError) { [weak self] in await self?.load(region: region) }
            }
        }
    }
}
