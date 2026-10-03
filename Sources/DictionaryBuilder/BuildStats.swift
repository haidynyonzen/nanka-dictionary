import Foundation
import GRDB

/// Prints row counts and file size so a bad build is obvious at a glance.
enum BuildStats {
    static let tables = ["meta", "tag", "entry", "kanji_form", "reading", "sense", "search_key", "gloss_fts", "gloss_exact", "kanji"]

    static func print(databaseAt url: URL, elapsed: Duration) throws {
        var config = Configuration()
        config.readonly = true
        let queue = try DatabaseQueue(path: url.path, configuration: config)
        Swift.print("\nBuilt \(url.path)")
        try queue.read { db in
            for table in tables {
                let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
                Swift.print("  \(table.padding(toLength: 12, withPad: " ", startingAt: 0)) \(count)")
            }
        }
        Swift.print("  file size    \(formattedSize(of: url))")
        Swift.print("  build time   \(elapsed)")
    }

    private static func formattedSize(of url: URL) -> String {
        let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return String(format: "%.1f MB (%d bytes)", Double(bytes) / 1_048_576, bytes)
    }
}
