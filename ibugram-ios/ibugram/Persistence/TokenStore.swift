import Foundation
import IBUgramKit

struct TokenPair: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresAt: Date

    init(accessToken: String, refreshToken: String, accessTokenExpiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
    }

    init(session: AuthSession, now: Date = .now) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.accessTokenExpiresAt = now.addingTimeInterval(TimeInterval(session.expiresIn))
    }

    var isAccessTokenExpired: Bool { accessTokenExpiresAt <= .now }
}

protocol TokenStoring: Sendable {
    func currentTokens() async -> TokenPair?
    func save(_ tokens: TokenPair) async throws
    func clear() async throws
}

actor KeychainTokenStore: TokenStoring {
    private let keychain: Keychain
    private let account: String
    private var cached: TokenPair?

    init(keychain: Keychain = Keychain(service: "ba.ibu.ibugram.tokens"), account: String = "session") {
        self.keychain = keychain
        self.account = account
    }

    func currentTokens() async -> TokenPair? {
        if let cached { return cached }
        guard let data = try? keychain.data(forAccount: account),
              let tokens = try? JSONDecoder().decode(TokenPair.self, from: data) else { return nil }
        cached = tokens
        return tokens
    }

    func save(_ tokens: TokenPair) async throws {
        try keychain.set(try JSONEncoder().encode(tokens), forAccount: account)
        cached = tokens
    }

    func clear() async throws {
        cached = nil
        try keychain.removeItem(forAccount: account)
    }
}

actor InMemoryTokenStore: TokenStoring {
    private var tokens: TokenPair?

    init(tokens: TokenPair? = nil) {
        self.tokens = tokens
    }

    func currentTokens() async -> TokenPair? { tokens }

    func save(_ tokens: TokenPair) async throws { self.tokens = tokens }

    func clear() async throws { tokens = nil }
}
