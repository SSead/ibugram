import Foundation

struct MultipartFormData: Sendable {
    struct Part: Sendable {
        let name: String
        let filename: String?
        let mimeType: String?
        let data: Data
    }

    let boundary: String
    private var parts: [Part] = []

    init(boundary: String = "ibugram.\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func addField(name: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        parts.append(Part(name: name, filename: nil, mimeType: nil, data: data))
    }

    mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        parts.append(Part(name: name, filename: filename, mimeType: mimeType, data: data))
    }

    func encoded() -> Data {
        var body = Data()
        for part in parts {
            body.append(line("--\(boundary)"))
            body.append(line(contentDisposition(for: part)))
            if let mimeType = part.mimeType {
                body.append(line("Content-Type: \(mimeType)"))
            }
            body.append(line(""))
            body.append(part.data)
            body.append(line(""))
        }
        body.append(line("--\(boundary)--"))
        return body
    }

    private func contentDisposition(for part: Part) -> String {
        guard let filename = part.filename else {
            return "Content-Disposition: form-data; name=\"\(part.name)\""
        }
        return "Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\""
    }

    private func line(_ string: String) -> Data {
        Data("\(string)\r\n".utf8)
    }
}
