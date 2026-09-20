import Foundation
import IBUgramKit

protocol APIRequesting: Sendable {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}
