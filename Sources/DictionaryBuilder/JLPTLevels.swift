import Foundation

/// Each JMdict entry's JLPT level (5 = N5, the easiest), read from the pinned per-level CSV files.
struct JLPTLevels {
    private let levels: [Int: Int]

    init(levels: [Int: Int] = [:]) {
        self.levels = levels
    }

    /// The level for a JMdict ent_seq, or nil when the word isn't on any list.
    func level(for entryID: Int) -> Int? {
        levels[entryID]
    }

    var count: Int { levels.count }

    /// Reads every level's file. A word on two lists (こしらえる is on N1 and N2) keeps the easier level.
    static func load(_ files: [Int: URL]) throws -> JLPTLevels {
        var levels: [Int: Int] = [:]
        for (level, url) in files {
            for entryID in try entryIDs(in: String(contentsOf: url, encoding: .utf8)) {
                levels[entryID] = max(levels[entryID] ?? 0, level)
            }
        }
        return JLPTLevels(levels: levels)
    }

    /// The first column of each row after the header. Every row is one line and the ID is never
    /// quoted, so the text before the first comma is enough. Rows without an ID are skipped.
    static func entryIDs(in csv: String) -> [Int] {
        csv.split(whereSeparator: \.isNewline).dropFirst().compactMap { line in
            Int(line.prefix { $0 != "," })
        }
    }
}
