import Fluent

/// Generated columns rather than triggers: Postgres recomputes them on every write, so
/// the index can never drift from the text it indexes.
struct AddFullTextSearch: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.execute(sql: """
            ALTER TABLE posts ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (to_tsvector('simple', coalesce(caption, ''))) STORED
            """)
        try await database.execute(sql: """
            ALTER TABLE users ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              to_tsvector('simple', coalesce(display_name, '') || ' ' || coalesce(username, ''))
            ) STORED
            """)
        try await database.execute(sql: "CREATE INDEX posts_search_vector_idx ON posts USING GIN (search_vector)")
        try await database.execute(sql: "CREATE INDEX users_search_vector_idx ON users USING GIN (search_vector)")
    }

    func revert(on database: any Database) async throws {
        try await database.execute(sql: "DROP INDEX IF EXISTS users_search_vector_idx")
        try await database.execute(sql: "DROP INDEX IF EXISTS posts_search_vector_idx")
        try await database.execute(sql: "ALTER TABLE users DROP COLUMN IF EXISTS search_vector")
        try await database.execute(sql: "ALTER TABLE posts DROP COLUMN IF EXISTS search_vector")
    }
}
