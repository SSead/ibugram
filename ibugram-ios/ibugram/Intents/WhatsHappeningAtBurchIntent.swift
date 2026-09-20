import AppIntents
import Foundation
import IBUgramKit

struct WhatsHappeningAtBurchIntent: AppIntent {
    static var title: LocalizedStringResource { "What's happening at Burch?" }
    static var description: IntentDescription {
        IntentDescription("Read campus events that are happening now.")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let events = await CampusHappeningsReader.load()
        return .result(dialog: IntentDialog(stringLiteral: CampusHappeningsSummary.dialog(for: events)))
    }
}

enum CampusHappeningsSummary {
    static func dialog(for events: [Event]) -> String {
        guard !events.isEmpty else {
            return "Nothing is happening on campus right now."
        }
        let lines = events.map { event in
            if let place = event.place?.name {
                "\(event.title) at \(place)"
            } else {
                event.title
            }
        }
        return lines.joined(separator: ". ") + "."
    }
}

enum CampusHappeningsReader {
    static func load(cache: any OfflineCaching = FileSystemOfflineCache()) async -> [Event] {
        if let fresh = await fetchFromAPI() {
            await cache.store(fresh, forKey: OfflineCacheKey.happeningNow)
            return fresh
        }
        return await cache.value([Event].self, forKey: OfflineCacheKey.happeningNow) ?? []
    }

    private static func fetchFromAPI() async -> [Event]? {
        let tokens = KeychainTokenStore()
        guard await tokens.currentTokens() != nil else { return nil }
        let client = APIClient(
            configuration: .development,
            tokenStore: tokens
        )
        return try? await client.send(EventEndpoints.HappeningNow()).items
    }
}
