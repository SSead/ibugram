import Foundation

enum MediaEndpoint {
    /// `POST /media` is `multipart/form-data` with a `file` field; max 10 MB, JPEG/PNG/HEIC.
    struct Upload: Endpoint {
        typealias Response = Media

        let imageData: Data
        let filename: String
        let mimeType: String
        let altText: String?

        var method: HTTPMethod { .post }
        var path: String { "/media" }
        var body: HTTPBody? {
            var form = MultipartFormData()
            form.addFile(name: "file", filename: filename, mimeType: mimeType, data: imageData)
            if let altText { form.addField(name: "alt_text", value: altText) }
            return .multipart(form)
        }
    }

    static func upload(
        jpeg data: Data,
        filename: String = "upload.jpg",
        altText: String? = nil
    ) -> Upload {
        Upload(imageData: data, filename: filename, mimeType: "image/jpeg", altText: altText)
    }
}
