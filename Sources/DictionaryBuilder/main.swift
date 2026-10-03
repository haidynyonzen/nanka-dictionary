import Foundation

/// Loads a pinned source file and decodes it. Decoding ~120 MB of JSON takes a few seconds.
func loadJSON<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
    try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
}

func run() async throws {
    let options = try Options.parse(Array(CommandLine.arguments.dropFirst()))
    let clock = ContinuousClock()

    let fetcher = SourceFetcher(cacheDirectory: options.cacheDirectory)
    let jmdictURL = try await fetcher.fetchJSON(PinnedSources.jmdict)
    let kanjidicURL = try await fetcher.fetchJSON(PinnedSources.kanjidic)
    var jlptURLs: [Int: URL] = [:]
    for (level, file) in PinnedJLPT.files { jlptURLs[level] = try await fetcher.fetchFile(file) }

    let start = clock.now
    print("Parsing sources ...")
    let jmdict = try loadJSON(JMdictFile.self, from: jmdictURL)
    let kanjidic = try loadJSON(KanjidicFile.self, from: kanjidicURL)
    let jlpt = try JLPTLevels.load(jlptURLs)

    let input = makeInput(jmdict: jmdict, kanjidic: kanjidic, jlpt: jlpt, fixture: options.isFixture)
    print("Writing \(input.words.count) entries and \(input.kanji.count) kanji ...")
    try DatabaseBuilder(outputURL: options.output).build(input)
    try BuildStats.print(databaseAt: options.output, elapsed: clock.now - start)
}

/// The full dictionary, or (for --fixture) only the fixture words and their kanji.
func makeInput(jmdict: JMdictFile, kanjidic: KanjidicFile, jlpt: JLPTLevels, fixture: Bool) -> BuildInput {
    guard fixture else {
        return BuildInput(
            jmdict: jmdict, words: jmdict.words, kanjidic: kanjidic, kanji: kanjidic.characters, jlpt: jlpt
        )
    }
    let words = FixtureSelection.select(from: jmdict.words)
    let literals = FixtureSelection.kanjiLiterals(in: words)
    let kanji = kanjidic.characters.filter { literals.contains($0.literal) }
    return BuildInput(jmdict: jmdict, words: words, kanjidic: kanjidic, kanji: kanji, jlpt: jlpt)
}

do {
    try await run()
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
