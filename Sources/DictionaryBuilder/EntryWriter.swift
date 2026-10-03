import DictionaryCore
import Foundation
import GRDB

/// Writes one JMdict word into `entry`, its child tables and the search indexes.
struct EntryWriter {
    let db: Database

    func write(_ word: JMdictWord) throws {
        guard let id = Int(word.id), let firstKana = word.kana.first else { return }
        try writeEntryRow(id: id, word: word, firstKana: firstKana)
        try writeKanjiForms(entryID: id, word.kanji)
        try writeReadings(entryID: id, word.kana)
        try writeSenses(entryID: id, word.sense)
    }

    /// Words JMdict marks "usually kana" (`uk`) show their kana: こっち, not 此方.
    static func headword(_ word: JMdictWord, firstKana: JMdictKana) -> String {
        let usuallyKana = word.sense.first?.misc.contains("uk") ?? false
        guard !usuallyKana, let kanji = word.kanji.first else { return firstKana.text }
        return kanji.text
    }

    /// Writes the `tag` table from the file's tag dictionary.
    static func writeTags(_ tags: [String: String], to db: Database) throws {
        for (code, description) in tags {
            try db.insert("INSERT INTO tag (code, description) VALUES (?, ?)", [code, description])
        }
    }

    // MARK: - Private

    private func writeEntryRow(id: Int, word: JMdictWord, firstKana: JMdictKana) throws {
        try db.insert(
            """
            INSERT INTO entry (id, headword, reading, gloss_summary, is_common, priority)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                id,
                Self.headword(word, firstKana: firstKana),
                firstKana.text,
                Self.glossSummary(word.sense.first),
                Self.isCommon(word),
                Self.priority(word),
            ]
        )
    }

    private func writeKanjiForms(entryID: Int, _ forms: [JMdictKanji]) throws {
        for (position, form) in forms.enumerated() {
            try db.insert(
                "INSERT INTO kanji_form (entry_id, position, text, is_common, tags) VALUES (?, ?, ?, ?, ?)",
                [entryID, position, form.text, form.common, jsonArray(form.tags)]
            )
            try writeSearchKey(form.text, entryID: entryID, kind: .kanji, position: position)
        }
    }

    private func writeReadings(entryID: Int, _ readings: [JMdictKana]) throws {
        for (position, reading) in readings.enumerated() {
            try db.insert(
                """
                INSERT INTO reading (entry_id, position, text, is_common, tags, applies_to_kanji)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                [entryID, position, reading.text, reading.common, jsonArray(reading.tags), jsonArray(reading.appliesToKanji)]
            )
            try writeSearchKey(reading.text, entryID: entryID, kind: .reading, position: position)
        }
    }

    private func writeSearchKey(_ text: String, entryID: Int, kind: DictionarySchema.KeyKind, position: Int) throws {
        // OR IGNORE: two forms of one entry can normalise to the same key (e.g. カニ / かに).
        try db.insert(
            "INSERT OR IGNORE INTO search_key (key, entry_id, kind, form_position) VALUES (?, ?, ?, ?)",
            [KanaNormalizer.searchKey(text), entryID, kind.rawValue, position]
        )
    }

    private func writeSenses(entryID: Int, _ senses: [JMdictSense]) throws {
        for (position, sense) in senses.enumerated() {
            try writeSenseRow(entryID: entryID, position: position, sense)
        }
    }

    private func writeSenseRow(entryID: Int, position: Int, _ sense: JMdictSense) throws {
        try db.insert(
            """
            INSERT INTO sense (entry_id, position, parts_of_speech, misc, fields, dialects, info, glosses,
                               applies_to_kanji, applies_to_kana, related, antonyms)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                entryID, position,
                jsonArray(sense.partOfSpeech), jsonArray(sense.misc), jsonArray(sense.field),
                jsonArray(sense.dialect), jsonArray(sense.info), jsonArray(sense.gloss.map(\.text)),
                jsonArray(sense.appliesToKanji), jsonArray(sense.appliesToKana),
                jsonArray(sense.related.map(Self.crossReferenceText)),
                jsonArray(sense.antonym.map(Self.crossReferenceText)),
            ]
        )
    }

    // MARK: - Derived values

    /// First ~3 glosses of the first sense: enough for a result row.
    static func glossSummary(_ sense: JMdictSense?) -> String {
        (sense?.gloss.prefix(3).map(\.text) ?? []).joined(separator: "; ")
    }

    static func isCommon(_ word: JMdictWord) -> Bool {
        word.kanji.contains { $0.common } || word.kana.contains { $0.common }
    }

    /// Ranking score, 0...100. jmdict-simplified keeps only a single `common` flag per form
    /// (the news1/ichi1/... markers are folded into it), so the score is built from that:
    /// 50 if any form is common, +30 if the main reading is common, +20 if the main
    /// spelling is common (or is a rarely-used kanji, so kana-first words like する are not penalised).
    static func priority(_ word: JMdictWord) -> Int {
        var score = 0
        if isCommon(word) { score += 50 }
        if word.kana.first?.common == true { score += 30 }
        if isMainSpellingCommon(word) { score += 20 }
        return score
    }

    private static func isMainSpellingCommon(_ word: JMdictWord) -> Bool {
        guard let mainKanji = word.kanji.first else { return word.kana.first?.common == true }
        // "rK" = rarely used kanji form: the kana reading is the normal way to write the word.
        return mainKanji.common || mainKanji.tags.contains("rK")
    }

    /// "食べる・たべる": text parts joined with a middle dot; the sense number is dropped.
    static func crossReferenceText(_ parts: [XrefPart]) -> String {
        parts.compactMap { part in
            if case .text(let text) = part { text } else { nil }
        }.joined(separator: "・")
    }
}
