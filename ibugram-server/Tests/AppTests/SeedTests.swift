import Fluent
import Testing
import Vapor
@testable import App

@Suite("Demo seed", .serialized)
struct DemoSeedTests {
    @Test("seeding twice leaves twelve users and fifteen posts")
    func seedingTwiceIsIdempotent() async throws {
        try await withTestServer { context in
            try await DemoSeed.run(on: context.app)
            try await DemoSeed.run(on: context.app)

            #expect(try await UserRecord.query(on: context.app.db).count() == DemoSeedDataset.users.count)
            #expect(try await PostRecord.query(on: context.app.db).count() == DemoSeedDataset.posts.count)
            #expect(try await SpaceRecord.query(on: context.app.db).count() == DemoSeedDataset.spaces.count)
            #expect(try await EventRecord.query(on: context.app.db).count() == DemoSeedDataset.events.count)
            #expect(try await UserRecord.query(on: context.app.db).filter(\.$username == "amina.hodzic").first() != nil)
        }
    }
}
