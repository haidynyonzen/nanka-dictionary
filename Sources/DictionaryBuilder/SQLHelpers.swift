import Foundation
import GRDB

/// Encodes strings as a JSON array, the format of every "list" column in the schema.
func jsonArray(_ values: [String]) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    // Encoding [String] cannot fail, so an empty array is only a formality.
    guard let data = try? encoder.encode(values) else { return "[]" }
    return String(decoding: data, as: UTF8.self)
}

extension Database {
    /// Runs an INSERT through a cached prepared statement — much faster than
    /// re-parsing the SQL for each of the ~1 million rows.
    func insert(_ sql: String, _ arguments: StatementArguments) throws {
        let statement = try cachedStatement(sql: sql)
        try statement.execute(arguments: arguments)
    }
}
