import DictionaryCore
import Foundation
import GRDB

/// Everything that goes into one database file.
struct BuildInput {
    let jmdict: JMdictFile
    let words: [JMdictWord]
    let kanjidic: KanjidicFile
    let kanji: [KanjidicCharacter]
}

/// Creates the SQLite file: schema, all rows in one transaction, then ANALYZE + FTS optimize + VACUUM.
struct DatabaseBuilder {
    let outputURL: URL

    func build(_ input: BuildInput) throws {
        try prepareOutputFile()
        let queue = try DatabaseQueue(path: outputURL.path)
        // One transaction: far faster than per-row commits, and a failure leaves no half-built tables.
        try queue.write { db in
            for statement in DictionarySchema.createStatements { try db.execute(sql: statement) }
            try writeMeta(input, to: db)
            try EntryWriter.writeTags(input.jmdict.tags, to: db)
            let entryWriter = EntryWriter(db: db)
            for word in input.words { try entryWriter.write(word) }
            // After the entries: ranking needs every entry's priority and senses.
            try GlossIndexWriter(db: db).write()
            let kanjiWriter = KanjiWriter(db: db)
            for character in input.kanji { try kanjiWriter.write(character) }
        }
        try optimize(queue)
    }

    // MARK: - Private

    private func prepareOutputFile() throws {
        let manager = FileManager.default
        try manager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if manager.fileExists(atPath: outputURL.path) { try manager.removeItem(at: outputURL) }
    }

    private func writeMeta(_ input: BuildInput, to db: Database) throws {
        let builtAt = ISO8601DateFormatter().string(from: Date())
        let rows: [(String, String)] = [
            (DictionarySchema.MetaKey.schemaVersion, String(DictionarySchema.version)),
            (DictionarySchema.MetaKey.jmdictVersion, "JMdict \(input.jmdict.dictDate) (jmdict-simplified \(PinnedSources.release))"),
            (DictionarySchema.MetaKey.kanjidicVersion, "KANJIDIC2 \(input.kanjidic.databaseVersion) (jmdict-simplified \(PinnedSources.release))"),
            (DictionarySchema.MetaKey.builtAt, builtAt),
            (DictionarySchema.MetaKey.attribution, attributionText),
        ]
        for (key, value) in rows {
            try db.insert("INSERT INTO meta (key, value) VALUES (?, ?)", [key, value])
        }
    }

    /// ANALYZE gives the query planner statistics; VACUUM shrinks the file. Neither can run inside a transaction.
    private func optimize(_ queue: DatabaseQueue) throws {
        try queue.writeWithoutTransaction { db in
            try db.execute(sql: "ANALYZE")
            // Merge the FTS index segments into one: smaller file, faster queries.
            try db.execute(sql: "INSERT INTO gloss_fts(gloss_fts) VALUES('optimize')")
            try db.execute(sql: "VACUUM")
        }
    }
}
