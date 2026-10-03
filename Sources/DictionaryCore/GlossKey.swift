/// The exact-match keys of an English gloss, shared by the builder and the app.
///
/// The builder stores one `gloss_exact` row per key; the app looks up the user's
/// query with `KanaNormalizer.searchKey`. Glosses use the same function, so both
/// sides lowercase and normalise identically.
public enum GlossKey {
    /// Up to two keys: the gloss without a trailing " (note)", and the gloss without a leading "to ".
    public static func keys(for gloss: String) -> [String] {
        let normalized = KanaNormalizer.searchKey(gloss)
        var keys = [withoutTrailingNote(normalized)]
        if let bare = withoutLeadingTo(normalized) { keys.append(bare) }
        return keys.filter { !$0.isEmpty }
    }

    // MARK: - Private

    /// "water (esp. cool or cold)" -> "water". Only when the gloss ends in ")", so
    /// "same (political) party" is not an exact match for "same".
    private static func withoutTrailingNote(_ gloss: String) -> String {
        guard gloss.hasSuffix(")"), let start = gloss.range(of: " (") else { return gloss }
        return String(gloss[..<start.lowerBound])
    }

    /// "to eat" -> "eat". Uses the raw gloss: "to water (plants)" is not an exact "water".
    /// A gloss of just "to" has no variant, so it keeps its own key.
    private static func withoutLeadingTo(_ gloss: String) -> String? {
        guard gloss.hasPrefix("to "), gloss.count > 3 else { return nil }
        return String(gloss.dropFirst(3))
    }
}
