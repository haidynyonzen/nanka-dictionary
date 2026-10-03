/// Detects whether text is Japanese, so search can pick the kana/kanji index or English full-text search.
public enum JapaneseScript {
    /// True when any character is kana (either width), a prolonged sound mark or a CJK ideograph.
    public static func containsJapanese(_ text: String) -> Bool {
        text.unicodeScalars.contains(where: isJapanese)
    }

    // MARK: - Private

    private static let japaneseRanges: [ClosedRange<UInt32>] = [
        0x3041...0x30FF,  // hiragana + katakana (includes ー)
        0xFF66...0xFF9F,  // half-width katakana
        0x4E00...0x9FFF,  // common CJK ideographs
        0x3400...0x4DBF,  // CJK extension A
        0x20000...0x2A6DF,  // CJK extension B (rare kanji in names)
    ]

    private static func isJapanese(_ scalar: Unicode.Scalar) -> Bool {
        japaneseRanges.contains { $0.contains(scalar.value) }
    }
}
