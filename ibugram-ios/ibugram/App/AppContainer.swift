import Foundation

struct AppContainer: Sendable {
    let api: any APIRequesting
    let tokenStore: any TokenStoring
    let realtime: WebSocketClient
    let cache: any OfflineCaching
    let imageIntelligence: any ImageIntelligenceProviding
    let textIntelligence: any TextIntelligenceProviding
    let imageLoader: RemoteImageLoader
    let sessionInvalidation: SessionInvalidationSignal
}

extension AppContainer {
    static func live(configuration: APIConfiguration = .development) -> AppContainer {
        let tokenStore = KeychainTokenStore()
        let sessionInvalidation = SessionInvalidationSignal()
        return AppContainer(
            api: APIClient(
                configuration: configuration,
                tokenStore: tokenStore,
                sessionInvalidation: sessionInvalidation
            ),
            tokenStore: tokenStore,
            realtime: WebSocketClient(configuration: configuration, tokenStore: tokenStore),
            cache: FileSystemOfflineCache(),
            imageIntelligence: VisionImageIntelligence(),
            textIntelligence: NaturalLanguageTextIntelligence(),
            imageLoader: RemoteImageLoader(),
            sessionInvalidation: sessionInvalidation
        )
    }

    static func preview(
        api: any APIRequesting = MockAPIClient(),
        tokens: TokenPair? = SampleData.tokens
    ) -> AppContainer {
        AppContainer(
            api: api,
            tokenStore: InMemoryTokenStore(tokens: tokens),
            realtime: WebSocketClient(configuration: .preview, tokenStore: InMemoryTokenStore()),
            cache: NullOfflineCache(),
            imageIntelligence: StubImageIntelligence(),
            textIntelligence: StubTextIntelligence(),
            imageLoader: RemoteImageLoader(),
            sessionInvalidation: SessionInvalidationSignal()
        )
    }
}
