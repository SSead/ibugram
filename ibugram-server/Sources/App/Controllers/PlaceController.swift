import Fluent
import Foundation
import IBUgramKit
import Vapor

struct PlaceController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {}
}

enum PlaceLookup {
    static func resolve(_ input: PlaceInput?, on database: any Database) async throws -> PlaceRecord? {
        guard let input else { return nil }
        if let id = input.id {
            guard let place = try await PlaceRecord.find(id, on: database) else {
                throw APIError.notFound("That place does not exist.")
            }
            return place
        }
        try validate(latitude: input.latitude, longitude: input.longitude)
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...120).contains(name.count) else {
            throw APIError.validationFailed(
                "A place needs a name between 1 and 120 characters.",
                details: ["place": .string("name must be 1 to 120 characters")]
            )
        }
        let place = PlaceRecord()
        place.id = UUID()
        place.name = name
        place.latitude = input.latitude
        place.longitude = input.longitude
        place.isCampusLocation = input.isCampusLocation
        try await place.create(on: database)
        return place
    }

    private static func validate(latitude: Double, longitude: Double) throws {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw APIError.validationFailed(
                "Those coordinates are not valid.",
                details: ["place": .string("latitude/longitude out of range")]
            )
        }
    }
}
