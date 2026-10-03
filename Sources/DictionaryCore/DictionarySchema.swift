/// SQL for the bundled, read-only dictionary database.
///
/// Shared by `tools/DictionaryBuilder` (writes it) and `DictionaryKit` (reads it),
/// so the two can never drift apart. Bump `version` whenever a statement changes.
public enum DictionarySchema {
    public static let version = 1

    /// Keys stored in the `meta` table.
    public enum MetaKey {
        public static let schemaVersion = "schema_version"
        public static let jmdictVersion = "jmdict_version"
        public static let kanjidicVersion = "kanjidic_version"
        public static let builtAt = "built_at"
        public static let attribution = "attribution"
    }

    /// `search_key.kind` values.
    public enum KeyKind: Int, Sendable {
        case kanji = 0
        case reading = 1
    }

    // JSON-array columns (tags, glosses, …) are stored as TEXT holding a JSON array of strings.
    public static let createStatements: [String] = [
        """
        CREATE TABLE meta (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
        """,
        // Abbreviation -> description for JMdict tags ("v5r" -> "Godan verb with 'ru' ending").
        """
        CREATE TABLE tag (
            code        TEXT PRIMARY KEY,
            description TEXT NOT NULL
        )
        """,
        // id is the JMdict ent_seq — the stable ID user data points at.
        // headword/reading/gloss_summary are denormalised so result lists need one query.
        """
        CREATE TABLE entry (
            id            INTEGER PRIMARY KEY,
            headword      TEXT    NOT NULL,
            reading       TEXT    NOT NULL,
            gloss_summary TEXT    NOT NULL,
            is_common     INTEGER NOT NULL DEFAULT 0,
            priority      INTEGER NOT NULL DEFAULT 0,
            jlpt          INTEGER
        )
        """,
        """
        CREATE TABLE kanji_form (
            entry_id  INTEGER NOT NULL REFERENCES entry(id),
            position  INTEGER NOT NULL,
            text      TEXT    NOT NULL,
            is_common INTEGER NOT NULL DEFAULT 0,
            tags      TEXT    NOT NULL DEFAULT '[]',
            PRIMARY KEY (entry_id, position)
        ) WITHOUT ROWID
        """,
        // applies_to_kanji: ["*"] means every kanji form.
        """
        CREATE TABLE reading (
            entry_id         INTEGER NOT NULL REFERENCES entry(id),
            position         INTEGER NOT NULL,
            text             TEXT    NOT NULL,
            is_common        INTEGER NOT NULL DEFAULT 0,
            tags             TEXT    NOT NULL DEFAULT '[]',
            applies_to_kanji TEXT    NOT NULL DEFAULT '["*"]',
            PRIMARY KEY (entry_id, position)
        ) WITHOUT ROWID
        """,
        """
        CREATE TABLE sense (
            entry_id         INTEGER NOT NULL REFERENCES entry(id),
            position         INTEGER NOT NULL,
            parts_of_speech  TEXT    NOT NULL DEFAULT '[]',
            misc             TEXT    NOT NULL DEFAULT '[]',
            fields           TEXT    NOT NULL DEFAULT '[]',
            dialects         TEXT    NOT NULL DEFAULT '[]',
            info             TEXT    NOT NULL DEFAULT '[]',
            glosses          TEXT    NOT NULL DEFAULT '[]',
            applies_to_kanji TEXT    NOT NULL DEFAULT '["*"]',
            applies_to_kana  TEXT    NOT NULL DEFAULT '["*"]',
            related          TEXT    NOT NULL DEFAULT '[]',
            antonyms         TEXT    NOT NULL DEFAULT '[]',
            PRIMARY KEY (entry_id, position)
        ) WITHOUT ROWID
        """,
        // Japanese lookup. FTS5 can't segment Japanese, so we index normalised forms
        // (see KanaNormalizer.searchKey) and use exact / prefix range queries instead.
        """
        CREATE TABLE search_key (
            key           TEXT    NOT NULL,
            entry_id      INTEGER NOT NULL REFERENCES entry(id),
            kind          INTEGER NOT NULL,
            form_position INTEGER NOT NULL,
            PRIMARY KEY (key, entry_id, kind, form_position)
        ) WITHOUT ROWID
        """,
        // English lookup: full-text search over glosses, with stemming.
        """
        CREATE VIRTUAL TABLE gloss_fts USING fts5(
            gloss,
            entry_id UNINDEXED,
            sense_position UNINDEXED,
            tokenize = 'porter unicode61 remove_diacritics 2'
        )
        """,
        """
        CREATE TABLE kanji (
            literal      TEXT PRIMARY KEY,
            grade        INTEGER,
            stroke_count INTEGER,
            jlpt         INTEGER,
            frequency    INTEGER,
            on_readings  TEXT NOT NULL DEFAULT '[]',
            kun_readings TEXT NOT NULL DEFAULT '[]',
            nanori       TEXT NOT NULL DEFAULT '[]',
            meanings     TEXT NOT NULL DEFAULT '[]',
            radicals     TEXT NOT NULL DEFAULT '[]'
        )
        """,
    ]
}
