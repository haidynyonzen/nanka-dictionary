import Testing
@testable import DictionaryCore

struct JapaneseScriptTests {
    @Test func detectsKanaAndKanji() {
        #expect(JapaneseScript.containsJapanese("たべる"))
        #expect(JapaneseScript.containsJapanese("スノーボード"))
        #expect(JapaneseScript.containsJapanese("ｽｲｿﾞｸｶﾝ"))
        #expect(JapaneseScript.containsJapanese("水"))
        #expect(JapaneseScript.containsJapanese("eat 食べる"))
    }

    @Test func latinAndEmptyAreNotJapanese() {
        #expect(!JapaneseScript.containsJapanese("aquarium"))
        #expect(!JapaneseScript.containsJapanese("ＡＱＵＡ"))
        #expect(!JapaneseScript.containsJapanese(""))
    }
}
