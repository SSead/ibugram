import Foundation

public enum IBUgramDateCoding {
    /// The contract mandates ISO-8601 UTC with fractional seconds on the wire.
    ///
    /// `ISO8601FormatStyle` truncates the fraction, so a timestamp parsed from `.482`
    /// would re-encode as `.481`. Rounding to whole milliseconds first keeps the value
    /// stable across an encode/decode cycle.
    public static func string(from date: Date) -> String {
        let totalMilliseconds = (date.timeIntervalSince1970 * 1000).rounded()
        let wholeSeconds = (totalMilliseconds / 1000).rounded(.down)
        let milliseconds = Int(totalMilliseconds - wholeSeconds * 1000)
        let secondsText = wholeSecondStyle.format(Date(timeIntervalSince1970: wholeSeconds))
        return secondsText.dropLast() + String(format: ".%03dZ", milliseconds)
    }

    /// Accepts the whole-second form too, because third-party tooling and hand-written
    /// fixtures routinely omit the fraction.
    public static func date(from string: String) -> Date? {
        (try? fractionalStyle.parse(string)) ?? (try? wholeSecondStyle.parse(string))
    }

    private static let fractionalStyle = Date.ISO8601FormatStyle(
        includingFractionalSeconds: true,
        timeZone: .gmt
    )

    private static let wholeSecondStyle = Date.ISO8601FormatStyle(
        includingFractionalSeconds: false,
        timeZone: .gmt
    )
}

extension JSONEncoder {
    public static var ibugram: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(IBUgramDateCoding.string(from: date))
        }
        return encoder
    }
}

extension JSONDecoder {
    public static var ibugram: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = IBUgramDateCoding.date(from: text) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected an ISO-8601 timestamp, found \(text)."
                )
            }
            return date
        }
        return decoder
    }
}
