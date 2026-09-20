import Vapor

struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {
        init() {}
    }

    var help: String {
        "Load a realistic IBU campus dataset into the current database."
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        try await DemoSeed.run(on: context.application)
    }
}
