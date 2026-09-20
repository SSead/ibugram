import IBUgramKit
import Vapor

/// Per-process sliding window. A multi-instance deployment would move this to Redis; the
/// protocol boundary is the middleware, so that swap does not touch a controller.
actor RequestRateLimiter {
    private var hits: [String: [Date]] = [:]

    func recordAndCheck(key: String, limit: Int, window: TimeInterval, now: Date = Date()) -> Bool {
        let cutoff = now.addingTimeInterval(-window)
        var recent = (hits[key] ?? []).filter { $0 > cutoff }
        guard recent.count < limit else {
            hits[key] = recent
            return false
        }
        recent.append(now)
        hits[key] = recent
        return true
    }

    func reset() {
        hits.removeAll()
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    let limiter: RequestRateLimiter
    let limit: Int
    let window: TimeInterval

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let key = "\(request.remoteAddress?.ipAddress ?? "unknown"):\(request.url.path)"
        guard await limiter.recordAndCheck(key: key, limit: limit, window: window) else {
            throw APIError(code: .rateLimited, message: "Too many requests. Try again shortly.")
        }
        return try await next.respond(to: request)
    }
}
