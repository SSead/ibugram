import Foundation
import IBUgramKit

enum EmailDomainValidator {
    enum Verdict: Equatable {
        case empty
        case malformed
        case domainNotAllowed(String)
        case allowed(role: UserRole)

        var isAllowed: Bool {
            if case .allowed = self { return true }
            return false
        }
    }

    static func verdict(for rawEmail: String) -> Verdict {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return .empty }

        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains(".") else { return .malformed }

        let domain = String(parts[1])
        guard IBUgram.allowedEmailDomains.contains(domain) else { return .domainNotAllowed(domain) }
        return .allowed(role: domain.hasPrefix("stu.") ? .student : .faculty)
    }

    static func normalized(_ rawEmail: String) -> String {
        rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension EmailDomainValidator.Verdict {
    var inlineMessage: String? {
        switch self {
        case .empty, .allowed:
            nil
        case .malformed:
            "Enter your full university email address."
        case .domainNotAllowed(let domain):
            "\(domain) is not a Burch address. Use @ibu.edu.ba or @stu.ibu.edu.ba."
        }
    }
}
