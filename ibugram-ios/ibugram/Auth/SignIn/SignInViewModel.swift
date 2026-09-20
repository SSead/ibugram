import Foundation
import IBUgramKit

@MainActor
@Observable
final class SignInViewModel: ErrorPresenting {
    var email = "" {
        didSet { hasEditedEmail = true }
    }

    var pendingVerification: PendingVerification?
    var presentedError: PresentedError?
    private(set) var isRequestingCode = false
    private var hasEditedEmail = false

    private let api: any APIRequesting

    init(api: any APIRequesting) {
        self.api = api
    }

    var verdict: EmailDomainValidator.Verdict {
        EmailDomainValidator.verdict(for: email)
    }

    var canRequestCode: Bool {
        verdict.isAllowed && !isRequestingCode
    }

    /// Nothing is flagged until the field has been touched, so the screen does not scold on open.
    var inlineMessage: String? {
        guard hasEditedEmail else { return "Only @ibu.edu.ba and @stu.ibu.edu.ba addresses can join." }
        return verdict.inlineMessage ?? "We will send a 6-digit code to this address."
    }

    var validationState: IBUTextField.ValidationState {
        guard hasEditedEmail else { return .neutral }
        return switch verdict {
        case .allowed: .valid
        case .empty: .neutral
        case .malformed, .domainNotAllowed: .invalid
        }
    }

    var roleHint: String? {
        guard case .allowed(let role) = verdict else { return nil }
        return role == .faculty ? "Faculty or staff account" : "Student account"
    }

    func requestCode() async {
        guard canRequestCode else { return }
        isRequestingCode = true
        defer { isRequestingCode = false }
        let normalized = EmailDomainValidator.normalized(email)
        do {
            let challenge = try await api.send(AuthEndpoint.requestCode(email: normalized))
            pendingVerification = PendingVerification(email: normalized, challenge: challenge)
        } catch {
            present(error) { [weak self] in await self?.requestCode() }
        }
    }
}
