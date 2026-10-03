import Foundation

/// Turns Japanese (and English) text into the canonical form used for search keys.
///
/// The builder and the app both call `searchKey(_:)`, so a query typed as
/// ｽｲｿﾞｸｶﾝ, スイゾクカン or すいぞくかん all hit the same index row.
public enum KanaNormalizer {
    /// Width-normalises, folds katakana to hiragana and lowercases Latin text.
    public static func searchKey(_ text: String) -> String {
        // NFKC turns half-width katakana and full-width Latin into their standard forms.
        let normalized = text.precomposedStringWithCompatibilityMapping
        // Re-compose after folding: half-width ｿ + ﾞ can come out of NFKC as そ + a combining mark.
        return katakanaToHiragana(normalized).precomposedStringWithCanonicalMapping.lowercased()
    }

    /// Converts katakana to hiragana, leaving everything else (including ー) untouched.
    public static func katakanaToHiragana(_ text: String) -> String {
        shiftKana(text, from: katakanaRange, by: -hiraganaKatakanaOffset)
    }

    /// Converts hiragana to katakana, leaving everything else untouched.
    public static func hiraganaToKatakana(_ text: String) -> String {
        shiftKana(text, from: hiraganaRange, by: hiraganaKatakanaOffset)
    }

    /// True when every character is hiragana, katakana or the long-vowel mark.
    public static func isKana(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy { scalar in
            hiraganaRange.contains(scalar.value)
                || katakanaRange.contains(scalar.value)
                || scalar.value == prolongedSoundMark
        }
    }

    // MARK: - Private

    // ぁ…ゖ plus ゝゞ, and the matching katakana block ァ…ヶ plus ヽヾ. They sit exactly 0x60 apart.
    private static let hiraganaRange: ClosedRange<UInt32> = 0x3041...0x309E
    private static let katakanaRange: ClosedRange<UInt32> = 0x30A1...0x30FE
    private static let hiraganaKatakanaOffset: Int32 = 0x60
    private static let prolongedSoundMark: UInt32 = 0x30FC

    private static func shiftKana(_ text: String, from range: ClosedRange<UInt32>, by offset: Int32) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            // Skip gaps with no counterpart (ゕゖ↔ヵヶ exist; ・ー etc. are outside the ranges).
            if range.contains(scalar.value),
               let shifted = Unicode.Scalar(UInt32(Int32(scalar.value) + offset)),
               isMappable(scalar.value) {
                scalars.append(shifted)
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    /// Code points inside the ranges that have no kana counterpart (e.g. ゗ ゘, ヷ–ヺ, ・ ー).
    private static func isMappable(_ value: UInt32) -> Bool {
        switch value {
        case 0x3097...0x309C, 0x30F7...0x30FC: false
        default: true
        }
    }
}
