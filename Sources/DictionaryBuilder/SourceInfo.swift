/// One pinned download from a jmdict-simplified release.
struct SourceFile {
    let assetName: String
    let sha256: String
    /// Name of the JSON file inside the archive (the release timestamp is dropped).
    let jsonName: String
}

/// The exact source data this builder accepts. Bump everything here together when updating.
enum PinnedSources {
    static let release = "3.6.2+20260928191014"
    static let baseURL = "https://github.com/scriptin/jmdict-simplified/releases/download/3.6.2%2B20260928191014/"

    static let jmdict = SourceFile(
        assetName: "jmdict-eng-3.6.2+20260928191014.json.tgz",
        sha256: "a4851e4dc63de5ac9d1a2af9d0a2b1d3c2c0e8811e72331a7dd3cab4b3e0f786",
        jsonName: "jmdict-eng-3.6.2.json"
    )
    static let kanjidic = SourceFile(
        assetName: "kanjidic2-en-3.6.2+20260928191014.json.tgz",
        sha256: "7e13c92d1a8e32286fe548f310aac7050bf1e1ba42b38d88d188046d514d4756",
        jsonName: "kanjidic2-en-3.6.2.json"
    )
}

/// One pinned plain file (no archive), checked by SHA-256 like the release assets.
struct PlainSourceFile {
    let url: String
    let fileName: String
    let sha256: String
}

/// JLPT vocabulary lists, one file per level: Jonathan Waller's lists (CC BY) with each word matched
/// to its JMdict entry by yomitan-jlpt-vocab (CC BY-SA 4.0). Pinned to one commit.
enum PinnedJLPT {
    static let commit = "b062d4e38c4bdd0950ae1d4ec55f04b176182e03"
    static let description = "Waller JLPT lists via yomitan-jlpt-vocab \(commit.prefix(7))"

    /// Keyed by level: 5 is N5, the easiest.
    static let files: [Int: PlainSourceFile] = [
        5: file(5, sha256: "07dc6f197b51cc076c65c3c9f23218d10c2b67f76545f5c1c4d9e3750495533a"),
        4: file(4, sha256: "a14dcc7fdc02259b22331a486c6ff66df74c16472c8aeb5a0ebe7e5fa8ee8eb4"),
        3: file(3, sha256: "bd4d68c59cfee861351e1bdf9d99818e434392201eabbed4d3657225fe53a3ac"),
        2: file(2, sha256: "42a4413326e857d701dc9659b2711637ab612304a339fe0d09f4f0f042d3a214"),
        1: file(1, sha256: "7a58f0584e9ec2b0299ccb9b109f3bd03e08b90d129a714307c0a1cb72f07b32"),
    ]

    private static func file(_ level: Int, sha256: String) -> PlainSourceFile {
        PlainSourceFile(
            url: "https://raw.githubusercontent.com/stephenmk/yomitan-jlpt-vocab/\(commit)/original_data/n\(level).csv",
            fileName: "jlpt-n\(level)-\(commit.prefix(7)).csv",
            sha256: sha256
        )
    }
}

/// Text stored in `meta.attribution`; the About screen shows it verbatim.
let attributionText = """
This app uses the JMdict and KANJIDIC2 dictionary files. These files are the property of the \
Electronic Dictionary Research and Development Group (EDRDG), and are used in conformity with the \
Group's licence (https://www.edrdg.org/edrdg/licence.html), Creative Commons Attribution-ShareAlike 4.0. \
The data was converted to JSON by jmdict-simplified (https://github.com/scriptin/jmdict-simplified). \
JLPT levels come from Jonathan Waller's JLPT Resources (http://www.tanos.co.uk/jlpt/), licensed \
Creative Commons Attribution, as matched to JMdict entries by yomitan-jlpt-vocab \
(https://github.com/stephenmk/yomitan-jlpt-vocab), licensed Creative Commons Attribution-ShareAlike 4.0. \
JLPT levels are unofficial: the test has published no word lists since 2010.
"""
