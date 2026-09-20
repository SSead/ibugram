import Foundation
import IBUgramKit

struct MediaURLBuilder: Sendable {
    let publicBaseURL: String

    func url(forMedia id: UUID) -> String {
        publicBaseURL + API.MediaRoutes.download(id: id).fullPath
    }

    func thumbnailURL(forMedia id: UUID) -> String {
        publicBaseURL + API.MediaRoutes.thumbnail(id: id).fullPath
    }
}

extension MediaRecord {
    func asDTO(urls: MediaURLBuilder) throws -> Media {
        let identifier = try requireID()
        return Media(
            id: identifier,
            url: urls.url(forMedia: identifier),
            thumbnailUrl: urls.thumbnailURL(forMedia: identifier),
            width: width,
            height: height,
            altText: altText,
            blurhash: blurhash
        )
    }
}
