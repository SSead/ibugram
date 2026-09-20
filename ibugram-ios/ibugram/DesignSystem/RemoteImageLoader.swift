import UIKit
import IBUgramKit

actor RemoteImageLoader {
    private let session: URLSession
    private let decodedLimit: Int
    private var decoded: [URL: UIImage] = [:]
    private var insertionOrder: [URL] = []
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    init(decodedLimit: Int = 120, diskCapacityInMegabytes: Int = 256) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1_024 * 1_024,
            diskCapacity: diskCapacityInMegabytes * 1_024 * 1_024
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: configuration)
        self.decodedLimit = decodedLimit
    }

    func cachedImage(for url: URL) -> UIImage? {
        decoded[url]
    }

    func image(for url: URL) async -> UIImage? {
        if let existing = decoded[url] { return existing }
        if let task = inFlight[url] { return await task.value }

        let task = Task<UIImage?, Never> { [session] in
            guard let (data, _) = try? await session.data(from: url) else { return nil }
            return UIImage(data: data)
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { cache(image, for: url) }
        return image
    }

    private func cache(_ image: UIImage, for url: URL) {
        decoded[url] = image
        insertionOrder.append(url)
        while insertionOrder.count > decodedLimit {
            let evicted = insertionOrder.removeFirst()
            decoded[evicted] = nil
        }
    }
}
