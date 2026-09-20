import Foundation

extension Error {
    var asAPIError: APIError {
        switch self {
        case let apiError as APIError:
            apiError
        case let urlError as URLError:
            urlError.code == .notConnectedToInternet ? .offline : .transport(urlError.localizedDescription)
        default:
            .server(status: -1, code: "internal_error", message: localizedDescription)
        }
    }
}
