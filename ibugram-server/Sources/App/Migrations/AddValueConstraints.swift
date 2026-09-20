import Fluent
import IBUgramKit

/// The enumerated columns are stored as text so the Swift enums remain the single source
/// of truth; these checks stop anything outside the application writing a value the
/// application cannot decode.
struct AddValueConstraints: AsyncMigration {
    private static var checks: [(table: String, name: String, column: String, values: [String])] {
        [
            ("users", "users_role_valid", "role", UserRole.allCases.map(\.rawValue)),
            ("spaces", "spaces_kind_valid", "kind", SpaceKind.allCases.map(\.rawValue)),
            ("spaces", "spaces_visibility_valid", "visibility", SpaceVisibility.allCases.map(\.rawValue)),
            (
                "space_memberships", "space_memberships_role_valid", "role",
                SpaceMembership.allCases.filter { $0 != .none }.map(\.rawValue)
            ),
            ("event_rsvps", "event_rsvps_status_valid", "status", RSVPStatus.allCases.map(\.rawValue)),
            ("conversations", "conversations_kind_valid", "kind", ConversationKind.allCases.map(\.rawValue)),
            ("notifications", "notifications_kind_valid", "kind", NotificationKind.allCases.map(\.rawValue)),
            ("reports", "reports_subject_valid", "subject", ReportSubject.allCases.map(\.rawValue)),
            ("reports", "reports_reason_valid", "reason", ReportReason.allCases.map(\.rawValue)),
            ("reports", "reports_status_valid", "status", ReportStatus.allCases.map(\.rawValue)),
            (
                "auth_sessions", "auth_sessions_revoked_reason_valid", "revoked_reason",
                SessionRevocationReason.allCases.map(\.rawValue)
            )
        ]
    }

    func prepare(on database: any Database) async throws {
        for check in Self.checks {
            let list = check.values.map { "'\($0)'" }.joined(separator: ", ")
            try await database.execute(sql: """
                ALTER TABLE \(unsafeRaw: check.table) ADD CONSTRAINT \(unsafeRaw: check.name)
                CHECK (\(unsafeRaw: check.column) IS NULL OR \(unsafeRaw: check.column) IN (\(unsafeRaw: list)))
                """)
        }
    }

    func revert(on database: any Database) async throws {
        for check in Self.checks.reversed() {
            try await database.execute(sql: """
                ALTER TABLE \(unsafeRaw: check.table) DROP CONSTRAINT IF EXISTS \(unsafeRaw: check.name)
                """)
        }
    }
}
