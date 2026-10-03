import DictionaryCore
import GRDB

/// Fills `gloss_fts` and `gloss_exact` after all entries are written, so ranking can
/// use every entry's priority and senses. Ranking here keeps the app's English search fast.
struct GlossIndexWriter {
    let db: Database

    func write() throws {
        try createGlossTable()
        try writeFullTextIndex()
        try writeExactKeys()
    }

    // MARK: - Private

    /// One row per gloss with everything ranking needs. TEMP: it vanishes with the connection.
    private func createGlossTable() throws {
        try db.execute(sql: """
            CREATE TEMP TABLE gloss_row AS
            SELECT s.entry_id, s.position AS sense_position, g.key AS gloss_index, g.value AS gloss,
                   length(g.value) AS gloss_length,
                   g.key = 0 AS is_first_gloss,
                   json_array_length(s.glosses) AS gloss_count,
                   e.priority,
                   (e.headword GLOB '[ァ-ヿ]*' AND NOT e.headword GLOB '*[^ァ-ヿ]*') AS is_loanword
            FROM sense s
            JOIN entry e ON e.id = s.entry_id, json_each(s.glosses) g
            """)
    }

    /// The app reads `gloss_fts WHERE MATCH ... LIMIT n` and relies on rowid order being
    /// roughly best-first (priority, then short glosses), so the first n hits are good
    /// candidates and FTS can stop early. The app re-ranks those candidates itself.
    private func writeFullTextIndex() throws {
        try db.execute(sql: """
            INSERT INTO gloss_fts (rowid, gloss, entry_id, sense_position)
            SELECT ROW_NUMBER() OVER (
                       ORDER BY priority DESC, gloss_length, entry_id, sense_position, gloss_index),
                   gloss, entry_id, sense_position
            FROM gloss_row
            ORDER BY 1
            """)
    }

    private func writeExactKeys() throws {
        try createKeyTable()
        try insertKeys()
        // Per (key, entry) keep the best gloss, then rank everything in one dense order.
        try db.execute(sql: """
            INSERT INTO gloss_exact (key, rank, entry_id)
            SELECT key,
                   ROW_NUMBER() OVER (
                       ORDER BY is_first_sense DESC, priority DESC, is_first_gloss DESC,
                                is_loanword, gloss_count, gloss_length, entry_id),
                   entry_id
            FROM (
                SELECT *, ROW_NUMBER() OVER (
                           PARTITION BY key, entry_id
                           ORDER BY is_first_sense DESC, is_first_gloss DESC, gloss_count) AS best
                FROM gloss_key)
            WHERE best = 1
            """)
    }

    private func createKeyTable() throws {
        try db.execute(sql: """
            CREATE TEMP TABLE gloss_key (
                key TEXT, entry_id INTEGER, is_first_sense INTEGER, priority INTEGER,
                is_first_gloss INTEGER, gloss_count INTEGER, is_loanword INTEGER, gloss_length INTEGER)
            """)
    }

    /// Keys are made in Swift, not SQL, so lowercasing matches `KanaNormalizer` (SQLite's lower() is ASCII-only).
    private func insertKeys() throws {
        let rows = try Row.fetchCursor(db, sql: """
            SELECT gloss, entry_id, sense_position = 0, priority, is_first_gloss,
                   gloss_count, is_loanword, gloss_length
            FROM gloss_row
            """)
        let insert = try db.makeStatement(sql: "INSERT INTO gloss_key VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
        while let row = try rows.next() {
            let gloss: String = row[0]
            for key in GlossKey.keys(for: gloss) {
                try insert.execute(arguments: [key, row[1], row[2], row[3], row[4], row[5], row[6], row[7]])
            }
        }
    }
}
