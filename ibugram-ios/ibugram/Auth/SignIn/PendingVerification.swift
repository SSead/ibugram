import Foundation
import IBUgramKit

/// Navigation value for the code-entry screen. Kept separate from the transport DTO so the
/// navigation stack does not depend on the wire format being `Hashable`.
struct PendingVerification: Hashable, Sendable {
    let email: String
    let expiresAt: Date
    let resendAfter: Int
    let debugCode: String?

    init(email: String, challenge: RequestCodeResponse) {
        self.email = email
        self.expiresAt = challenge.expiresAt
        self.resendAfter = challenge.resendAfter
        self.debugCode = challenge.debugCode
    }
}
