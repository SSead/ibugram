import Foundation

struct PresentedError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let retry: (@MainActor () async -> Void)?

    init(title: String = "Something went wrong", message: String, retry: (@MainActor () async -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retry = retry
    }

    init(_ error: any Error, retry: (@MainActor () async -> Void)? = nil) {
        let apiError = error.asAPIError
        self.title = Self.title(for: apiError)
        self.message = apiError.userFacingDescription
        self.retry = apiError.isRetryable ? retry : nil
    }

    private static func title(for error: APIError) -> String {
        switch error {
        case .offline: "No connection"
        case .unauthorized: "Session expired"
        case .forbidden: "Not allowed"
        case .notFound: "Not found"
        case .validationFailed: "Check your details"
        case .otpInvalid, .otpExpired, .otpThrottled, .domainNotAllowed: "Sign-in problem"
        case .rateLimited: "Slow down"
        default: "Something went wrong"
        }
    }
}

/// Anything that can surface a failed request to the user does it through this one property,
/// so every screen presents errors identically.
@MainActor
protocol ErrorPresenting: AnyObject {
    var presentedError: PresentedError? { get set }
}

extension ErrorPresenting {
    func present(_ error: any Error, retry: (@MainActor () async -> Void)? = nil) {
        presentedError = PresentedError(error, retry: retry)
    }
}
