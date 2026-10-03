import Testing
@testable import DictionaryCore

struct GlossKeyTests {
    @Test func plainGlossIsItsOwnKey() {
        #expect(GlossKey.keys(for: "same") == ["same"])
        #expect(GlossKey.keys(for: "Water") == ["water"])
    }

    @Test func midGlossNoteDoesNotMakeAnExactMatch() {
        #expect(!GlossKey.keys(for: "same (political) party").contains("same"))
    }

    @Test func trailingNoteIsStripped() {
        #expect(GlossKey.keys(for: "water (esp. cool or cold)").contains("water"))
    }

    @Test func leadingToIsStrippedToo() {
        #expect(GlossKey.keys(for: "to eat") == ["to eat", "eat"])
    }

    @Test func toVerbWithNoteIsNotAnExactMatchForTheBareVerb() {
        #expect(!GlossKey.keys(for: "to water (plants)").contains("water"))
    }

    @Test func aloneToKeepsItsKey() {
        #expect(GlossKey.keys(for: "to") == ["to"])
    }
}
