import Foundation

/// Picks the small word list used for the test fixture database.
enum FixtureSelection {
    /// Words from the owner's vocab sheets, plus a few common ones for English-search tests.
    static let targets: [String] = [
        "着物", "水族館", "雰囲気", "街", "旅館", "朝食", "観光", "出発", "珍しい", "伝統的",
        "泥棒", "犯人", "会議", "警察", "置く", "包む", "貼る", "焼く", "間違える", "見つける",
        "比べる", "連絡", "少し", "カニ", "こっち", "どっち", "スノーボード", "ガソリン", "食べる", "見る",
        // Extras: prefix search (食べ物), a kana-only verb (する), English lookups (water, dog, book).
        "食べ物", "する", "水", "犬", "本", "猫",
    ]

    /// Targets whose spelling is shared by several entries: the reading picks the one we mean.
    private static let readingHints: [String: String] = ["街": "まち"]

    /// For each target, the best entry having a kanji or kana form exactly equal to it.
    static func select(from words: [JMdictWord]) -> [JMdictWord] {
        let wanted = Set(targets)
        var best: [String: JMdictWord] = [:]
        for word in words {
            for form in Set(formTexts(of: word)).intersection(wanted) where matchesHint(word, form) {
                if let current = best[form], !isBetter(word, than: current, for: form) { continue }
                best[form] = word
            }
        }
        // Different targets can resolve to the same entry, so de-duplicate by id.
        var seen = Set<String>()
        return targets.compactMap { best[$0] }.filter { seen.insert($0.id).inserted }
    }

    /// Every distinct CJK ideograph used in the selected entries' spellings.
    static func kanjiLiterals(in words: [JMdictWord]) -> Set<String> {
        var literals = Set<String>()
        for scalar in words.flatMap(\.kanji).flatMap(\.text.unicodeScalars) where isIdeograph(scalar) {
            literals.insert(String(scalar))
        }
        return literals
    }

    // MARK: - Private

    private static func formTexts(of word: JMdictWord) -> [String] {
        word.kanji.map(\.text) + word.kana.map(\.text)
    }

    private static func matchesHint(_ word: JMdictWord, _ form: String) -> Bool {
        guard let reading = readingHints[form] else { return true }
        return word.kana.first?.text == reading
    }

    /// An entry headed by the target beats one that only lists it as a variant; then priority, then
    /// the lower id, so the fixture is reproducible.
    private static func isBetter(_ candidate: JMdictWord, than current: JMdictWord, for form: String) -> Bool {
        let (a, b) = (score(candidate, form), score(current, form))
        return a != b ? a > b : (Int(candidate.id) ?? 0) < (Int(current.id) ?? 0)
    }

    private static func score(_ word: JMdictWord, _ form: String) -> Int {
        let headword = word.kanji.first?.text ?? word.kana.first?.text
        return EntryWriter.priority(word) + (headword == form ? 1000 : 0)
    }

    private static func isIdeograph(_ scalar: Unicode.Scalar) -> Bool {
        (0x4E00...0x9FFF).contains(scalar.value) || (0x3400...0x4DBF).contains(scalar.value)
    }
}
