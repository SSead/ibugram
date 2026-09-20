import Foundation

extension Date.ISO8601FormatStyle {
    /// The contract specifies ISO-8601 with fractional seconds; whole seconds is accepted
    /// on decode so a server that omits them does not break the client.
    static let ibugramFractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    static let ibugramWholeSeconds = Date.ISO8601FormatStyle()
}

extension JSONDecoder {
    static var ibugram: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = try? Date(raw, strategy: Date.ISO8601FormatStyle.ibugramFractionalSeconds) {
                return date
            }
            return try Date(raw, strategy: Date.ISO8601FormatStyle.ibugramWholeSeconds)
        }
        return decoder
    }
}

extension JSONEncoder {
    static var ibugram: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(Date.ISO8601FormatStyle.ibugramFractionalSeconds))
        }
        return encoder
    }
}
