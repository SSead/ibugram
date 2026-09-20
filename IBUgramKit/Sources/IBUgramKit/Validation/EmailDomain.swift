import Foundation

public enum EmailDomain: String, CaseIterable, Codable, Sendable, Hashable {
    case faculty = "ibu.edu.ba"
    case student = "stu.ibu.edu.ba"

    public var role: UserRole {
        switch self {
        case .faculty: .faculty
        case .student: .student
        }
    }
}

public enum EmailAddress {
    /// Lowercased and trimmed; `nil` when the text is not a single well-formed address.
    public static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let local = parts[0]
        let domain = parts[1]
        guard !local.isEmpty, !domain.isEmpty, domain.contains(".") else { return nil }
        guard !trimmed.contains(where: \.isWhitespace) else { return nil }
        guard !domain.hasPrefix("."), !domain.hasSuffix("."), !domain.contains("..") else { return nil }
        return trimmed
    }

    public static func localPart(of text: String) -> String? {
        normalized(text).map { String($0.split(separator: "@")[0]) }
    }

    public static func domain(of text: String) -> EmailDomain? {
        guard let normalized = normalized(text) else { return nil }
        return EmailDomain(rawValue: String(normalized.split(separator: "@")[1]))
    }

    public static func isAllowed(_ text: String) -> Bool {
        domain(of: text) != nil
    }

    public static func role(for text: String) -> UserRole? {
        domain(of: text)?.role
    }
}

public enum Username {
    public static let minimumLength = 3
    public static let maximumLength = 30

    /// The server hands out `user_<hex>` placeholders to accounts that have not finished
    /// onboarding, so the prefix cannot be claimed by a person.
    public static let reservedPrefix = "user_"

    public static func isValid(_ candidate: String) -> Bool {
        validate(candidate) == nil
    }

    /// Returns the reason the candidate is unusable, or `nil` when it is acceptable.
    public static func validate(_ candidate: String) -> UsernameProblem? {
        guard candidate.count >= minimumLength else { return .tooShort }
        guard candidate.count <= maximumLength else { return .tooLong }
        guard candidate.lowercased() == candidate else { return .notLowercased }
        guard candidate.allSatisfy(isAllowedCharacter) else { return .illegalCharacter }
        guard let first = candidate.first, first.isLetter || first.isNumber else { return .badBoundary }
        guard let last = candidate.last, last.isLetter || last.isNumber else { return .badBoundary }
        guard !candidate.contains("..") && !candidate.contains("__") else { return .repeatedSeparator }
        guard !candidate.hasPrefix(reservedPrefix) else { return .reserved }
        return nil
    }

    /// Best-effort suggestion derived from an email local part; may still be taken.
    public static func suggestion(fromEmailLocalPart localPart: String) -> String {
        let mapped = localPart.lowercased().map { isAllowedCharacter($0) ? $0 : "." }
        var candidate = String(mapped)
        while candidate.contains("..") {
            candidate = candidate.replacingOccurrences(of: "..", with: ".")
        }
        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "._"))
        if candidate.count > maximumLength {
            candidate = String(candidate.prefix(maximumLength))
        }
        return candidate
    }

    private static func isAllowedCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "." || character == "_")
    }
}

public enum UsernameProblem: String, Sendable, Hashable {
    case tooShort
    case tooLong
    case notLowercased
    case illegalCharacter
    case badBoundary
    case repeatedSeparator
    case reserved
}
