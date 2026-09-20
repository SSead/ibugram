import Foundation
import Testing
@testable import ibugram
import IBUgramKit
import MapKit

@Suite("Map bounding box")
struct MapBoundingBoxTests {
    @Test("the API query is minLon,minLat,maxLon,maxLat")
    func queryOrderMatchesContract() throws {
        let box = BoundingBox(
            minimumLongitude: 18.30,
            minimumLatitude: 43.81,
            maximumLongitude: 18.32,
            maximumLatitude: 43.83
        )
        let parts = box.queryValue.split(separator: ",")
        #expect(parts.count == 4)
        let parsed = try #require(MapBoundingBox.fromQuery(box.queryValue))
        #expect(parsed.minimumLongitude == 18.30)
        #expect(parsed.minimumLatitude == 43.81)
        #expect(parsed.maximumLongitude == 18.32)
        #expect(parsed.maximumLatitude == 43.83)
    }

    @Test("an inverted bbox is swapped into a valid range")
    func invertedBoxIsNormalized() {
        let box = MapBoundingBox.validated(
            minLongitude: 18.32,
            minLatitude: 43.83,
            maxLongitude: 18.30,
            maxLatitude: 43.81
        )
        #expect(box?.minimumLongitude == 18.30)
        #expect(box?.minimumLatitude == 43.81)
        #expect(box?.maximumLongitude == 18.32)
        #expect(box?.maximumLatitude == 43.83)
    }

    @Test("coordinates outside the globe are clamped")
    func outOfRangeValuesAreClamped() {
        let box = MapBoundingBox.validated(
            minLongitude: -200,
            minLatitude: -100,
            maxLongitude: 200,
            maxLatitude: 100
        )
        #expect(box?.minimumLongitude == -180)
        #expect(box?.minimumLatitude == -90)
        #expect(box?.maximumLongitude == 180)
        #expect(box?.maximumLatitude == 90)
    }

    @Test("a zero-area bbox is rejected")
    func zeroAreaIsRejected() {
        #expect(
            MapBoundingBox.validated(
                minLongitude: 18.31,
                minLatitude: 43.818,
                maxLongitude: 18.31,
                maxLatitude: 43.818
            ) == nil
        )
        #expect(MapBoundingBox.fromQuery("not-a-box") == nil)
        #expect(MapBoundingBox.fromQuery("18.3,43.8,18.4") == nil)
    }

    @Test("the campus region produces a bbox around Sarajevo / IBU")
    func campusRegionProducesBBox() throws {
        let box = try #require(MapBoundingBox.from(region: MapBoundingBox.campusRegion))
        #expect(box.minimumLatitude < 43.818)
        #expect(box.maximumLatitude > 43.818)
        #expect(box.minimumLongitude < 18.310)
        #expect(box.maximumLongitude > 18.310)
    }

    @Test("map pins open events and posts by id")
    func pinsEncodeRoutes() {
        let pins = CampusMapPin.pins(from: MapFixtures.contents)
        #expect(pins.contains { $0.route == .event(id: EventFixtures.openDay.id) })
        #expect(pins.contains { $0.route == .post(id: FeedFixtures.singleImage.id) })
        #expect(pins.allSatisfy { pin in
            switch pin.id {
            case .event: pin.systemImage == "calendar"
            case .post: pin.systemImage == "photo"
            }
        })
    }
}

@Suite("Map contents loading")
@MainActor
struct CampusMapViewModelTests {
    @Test("a valid region fetches map contents from GET /events/map")
    func loadSendsBBoxQuery() async {
        let client = ScriptedAPIClient(stubs: MapFixtures.stubs)
        let viewModel = CampusMapViewModel(api: client)
        await viewModel.load(region: MapBoundingBox.campusRegion)

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.pins.isEmpty == false)
        let calls = await client.recordedCalls()
        #expect(calls.contains("GET /events/map"))
        let bbox = await client.queryValue("bbox")
        #expect(bbox != nil)
        #expect(MapBoundingBox.fromQuery(bbox ?? "") != nil)
    }
}
