import Foundation
import IBUgramKit

@MainActor
@Observable
final class VerifyCodeViewModel: ErrorPresenting {
    static let codeLength = 6

    var code = "" {
        didSet { sanitizeCode() }
    }

    var presentedError: PresentedError?
    private(set) var isVerifying = false
    private(set) var isResending = false
    private(set) var secondsUntilResend: Int
    private(set) var hasFailedAttempt = false

    let verification: PendingVerification
    private let api: any APIRequesting
    private var countdown: Task<Void, Never>?

    init(verification: PendingVerification, api: any APIRequesting) {
        self.verification = verification
        self.api = api
        self.secondsUntilResend = verification.resendAfter
    }

    var canSubmit: Bool {
        code.count == Self.codeLength && !isVerifying
    }

    var canResend: Bool {
        secondsUntilResend == 0 && !isResending
    }

    var resendTitle: String {
        secondsUntilResend == 0 ? "Send a new code" : "Send a new code in \(secondsUntilResend)s"
    }

    func startResendCountdown() {
        countdown?.cancel()
        countdown = Task { [weak self] in
            while let self, self.secondsUntilResend > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.secondsUntilResend = max(0, self.secondsUntilResend - 1)
            }
        }
    }

    func stopResendCountdown() {
        countdown?.cancel()
        countdown = nil
    }

    func verify() async -> AuthSession? {
        guard canSubmit else { return nil }
        isVerifying = true
        defer { isVerifying = false }
        do {
            return try await api.send(AuthEndpoint.verifyCode(email: verification.email, code: code))
        } catch {
            hasFailedAttempt = true
            code = ""
            present(error)
            return nil
        }
    }

    func resendCode() async {
        guard canResend else { return }
        isResending = true
        defer { isResending = false }
        do {
            let challenge = try await api.send(AuthEndpoint.requestCode(email: verification.email))
            secondsUntilResend = challenge.resendAfter
            hasFailedAttempt = false
            startResendCountdown()
        } catch {
            present(error)
        }
    }

    /// Accepts codes pasted with spaces or dashes by keeping only the first six digits.
    private func sanitizeCode() {
        let digits = String(code.filter(\.isNumber).prefix(Self.codeLength))
        guard digits != code else { return }
        code = digits
    }
}
