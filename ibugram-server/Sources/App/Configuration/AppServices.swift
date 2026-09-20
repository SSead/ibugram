import Vapor

/// The application-scoped collaborators. Controllers reach them through the request so no
/// type constructs its own dependencies.
struct AppServices: Sendable {
    var emailSender: any EmailSender
    var mediaStore: any MediaStore
    var imageProcessor: ImageProcessor
    var otp: OTPService
    var tokens: TokenService
    var accounts: AccountService
    var urls: MediaURLBuilder
    var authRateLimiter: RequestRateLimiter
}

extension Application {
    private struct ServicesKey: StorageKey {
        typealias Value = AppServices
    }

    var dependencies: AppServices {
        get {
            guard let stored = storage[ServicesKey.self] else {
                fatalError("Application.dependencies read before configure(_:) ran.")
            }
            return stored
        }
        set { storage[ServicesKey.self] = newValue }
    }
}

extension Request {
    var dependencies: AppServices { application.dependencies }
}
