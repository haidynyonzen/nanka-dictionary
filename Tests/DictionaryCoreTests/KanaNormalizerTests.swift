import Testing
@testable import DictionaryCore

struct KanaNormalizerTests {
    @Test func foldsKatakanaAndHalfWidthToHiragana() {
        #expect(KanaNormalizer.searchKey("スイゾクカン") == "すいぞくかん")
        #expect(KanaNormalizer.searchKey("ｽｲｿﾞｸｶﾝ") == "すいぞくかん")
    }

    @Test func composesHalfWidthVoicingMarks() {
        // ｽ ｲ ｿ ﾞ ｸ ｶ ﾝ written as scalars, so the source file cannot pre-compose them.
        let halfWidth = "\u{FF7D}\u{FF72}\u{FF7F}\u{FF9E}\u{FF78}\u{FF76}\u{FF9D}"
        #expect(KanaNormalizer.searchKey(halfWidth) == "すいぞくかん")
    }

    @Test func keepsLongVowelMarkAndKanji() {
        #expect(KanaNormalizer.searchKey("スノーボード") == "すのーぼーど")
        #expect(KanaNormalizer.searchKey("水族館") == "水族館")
    }

    @Test func lowercasesAndNarrowsLatin() {
        #expect(KanaNormalizer.searchKey("ＡＱＵＡ") == "aqua")
    }

    @Test func detectsKana() {
        #expect(KanaNormalizer.isKana("こっち"))
        #expect(KanaNormalizer.isKana("ショッピングセンター"))
        #expect(!KanaNormalizer.isKana("着物"))
    }
}
