import Foundation
import GRDB

/// Writes KANJIDIC2 characters into the `kanji` table.
struct KanjiWriter {
    let db: Database

    func write(_ character: KanjidicCharacter) throws {
        let readings = character.readingMeaning?.groups.flatMap(\.readings) ?? []
        try db.insert(
            """
            INSERT INTO kanji (literal, grade, stroke_count, jlpt, frequency,
                               on_readings, kun_readings, nanori, meanings, radicals)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                character.literal,
                character.misc.grade,
                // The first stroke count is the accepted one; the rest are common miscounts.
                character.misc.strokeCounts.first,
                character.misc.jlptLevel,
                character.misc.frequency,
                jsonArray(Self.values(of: "ja_on", in: readings)),
                jsonArray(Self.values(of: "ja_kun", in: readings)),
                jsonArray(character.readingMeaning?.nanori ?? []),
                jsonArray(Self.englishMeanings(character)),
                jsonArray(Self.classicalRadicals(character)),
            ]
        )
    }

    // MARK: - Private

    private static func values(of type: String, in readings: [KanjidicReading]) -> [String] {
        readings.filter { $0.type == type }.map(\.value)
    }

    private static func englishMeanings(_ character: KanjidicCharacter) -> [String] {
        let groups = character.readingMeaning?.groups ?? []
        return groups.flatMap(\.meanings).filter { $0.lang == "en" }.map(\.value)
    }

    /// Kangxi radical numbers as strings, e.g. ["85"]. Kept as text so the column stays a string array.
    private static func classicalRadicals(_ character: KanjidicCharacter) -> [String] {
        character.radicals.filter { $0.type == "classical" }.map { String($0.value) }
    }
}
