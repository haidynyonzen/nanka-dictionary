import Foundation

// Codable mirrors of the jmdict-simplified JSON (see that project's README).
// Only the fields we store are listed; the decoder ignores the rest.

struct JMdictFile: Decodable {
    let dictDate: String
    /// Tag code -> description, for every tag used anywhere in the file.
    let tags: [String: String]
    let words: [JMdictWord]
}

struct JMdictWord: Decodable {
    let id: String
    let kanji: [JMdictKanji]
    let kana: [JMdictKana]
    let sense: [JMdictSense]
}

struct JMdictKanji: Decodable {
    let common: Bool
    let text: String
    let tags: [String]
}

struct JMdictKana: Decodable {
    let common: Bool
    let text: String
    let tags: [String]
    let appliesToKanji: [String]
}

struct JMdictSense: Decodable {
    let partOfSpeech: [String]
    let appliesToKanji: [String]
    let appliesToKana: [String]
    /// Cross-references like ["食べる", "たべる", 1]: text parts mixed with a sense number.
    let related: [[XrefPart]]
    let antonym: [[XrefPart]]
    let field: [String]
    let dialect: [String]
    let misc: [String]
    let info: [String]
    let gloss: [JMdictGloss]
}

struct JMdictGloss: Decodable {
    let text: String
}

/// A cross-reference part is either text or a sense number.
enum XrefPart: Decodable {
    case text(String)
    case number(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Int.self) {
            self = .number(number)
        } else {
            self = .text(try container.decode(String.self))
        }
    }
}

struct KanjidicFile: Decodable {
    let version: String
    let databaseVersion: String
    let characters: [KanjidicCharacter]
}

struct KanjidicCharacter: Decodable {
    let literal: String
    let radicals: [KanjidicRadical]
    let misc: KanjidicMisc
    let readingMeaning: KanjidicReadingMeaning?
}

struct KanjidicRadical: Decodable {
    let type: String
    let value: Int
}

struct KanjidicMisc: Decodable {
    let grade: Int?
    let strokeCounts: [Int]
    let frequency: Int?
    let jlptLevel: Int?
}

struct KanjidicReadingMeaning: Decodable {
    let groups: [KanjidicGroup]
    let nanori: [String]
}

struct KanjidicGroup: Decodable {
    let readings: [KanjidicReading]
    let meanings: [KanjidicMeaning]
}

struct KanjidicReading: Decodable {
    let type: String
    let value: String
}

struct KanjidicMeaning: Decodable {
    let lang: String
    let value: String
}
