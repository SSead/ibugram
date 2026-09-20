import Vapor

protocol EmailSender: Sendable {
    func sendVerificationCode(_ code: String, to address: String, expiresIn minutes: Int) async throws
}

/// Development transport. An SMTP implementation drops in behind the same protocol
/// without touching the auth service.
struct ConsoleEmailSender: EmailSender {
    let logger: Logger

    func sendVerificationCode(_ code: String, to address: String, expiresIn minutes: Int) async throws {
        logger.notice("IBUgram sign-in code for \(address): \(code) (valid \(minutes) minutes)")
    }
}
