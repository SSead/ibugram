import Foundation

struct DeviceSession: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let deviceName: String?
    let userAgent: String?
    let ipAddress: String?
    let isCurrent: Bool
    let createdAt: Date
    let lastUsedAt: Date
    let expiresAt: Date

    var title: String {
        if let deviceName, !deviceName.isEmpty { return deviceName }
        if let userAgent, !userAgent.isEmpty { return userAgent }
        return "This device"
    }
}

enum SettingsEndpoints {
    struct Sessions: Endpoint {
        typealias Response = [DeviceSession]

        var path: String { "/auth/sessions" }
    }

    struct RevokeSession: Endpoint {
        typealias Response = EmptyResponse

        let id: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/auth/sessions/\(id.uuidString)" }
    }
}
