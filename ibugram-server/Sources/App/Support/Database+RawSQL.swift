import Fluent
import SQLKit

enum DatabaseCapabilityError: Error {
    case rawSQLUnsupported
}

extension Database {
    /// Migrations reach for raw SQL where Fluent has no vocabulary: partial and
    /// functional indexes, check constraints, generated `tsvector` columns and triggers.
    func execute(sql query: SQLQueryString) async throws {
        guard let sqlDatabase = self as? any SQLDatabase else {
            throw DatabaseCapabilityError.rawSQLUnsupported
        }
        try await sqlDatabase.raw(query).run()
    }
}
