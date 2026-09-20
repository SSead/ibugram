import Foundation

enum CaptionToken: Equatable, Sendable {
    case text(String)
    case hashtag(String)
    case mention(String)
}

enum CaptionTokenizer {
    static func tokens(in caption: String) -> [CaptionToken] {
        var tokens: [CaptionToken] = []
        var buffer = ""
        var marker: Character?
        var body = ""

        for character in caption {
            if let currentMarker = marker {
                if isBodyCharacter(character, marker: currentMarker) {
                    body.append(character)
                    continue
                }
                appendMarked(marker: currentMarker, body: body, buffer: &buffer, tokens: &tokens)
                marker = nil
                body = ""
            }

            if character == "#" || character == "@" {
                if !buffer.isEmpty {
                    tokens.append(.text(buffer))
                    buffer = ""
                }
                marker = character
                body = ""
            } else {
                buffer.append(character)
            }
        }

        if let currentMarker = marker {
            appendMarked(marker: currentMarker, body: body, buffer: &buffer, tokens: &tokens)
        }
        if !buffer.isEmpty {
            tokens.append(.text(buffer))
        }
        return tokens
    }

    private static func appendMarked(
        marker: Character,
        body: String,
        buffer: inout String,
        tokens: inout [CaptionToken]
    ) {
        if body.isEmpty {
            buffer.append(marker)
            return
        }
        if marker == "#" {
            tokens.append(.hashtag(body))
        } else {
            tokens.append(.mention(body))
        }
    }

    private static func isBodyCharacter(_ character: Character, marker: Character) -> Bool {
        if character.isLetter || character.isNumber || character == "_" { return true }
        return marker == "@" && character == "."
    }
}
