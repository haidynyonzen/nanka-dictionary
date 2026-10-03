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

/// Text stored in `meta.attribution`; the About screen shows it verbatim.
let attributionText = """
This app uses the JMdict and KANJIDIC2 dictionary files. These files are the property of the \
Electronic Dictionary Research and Development Group (EDRDG), and are used in conformity with the \
Group's licence (https://www.edrdg.org/edrdg/licence.html), Creative Commons Attribution-ShareAlike 4.0. \
The data was converted to JSON by jmdict-simplified (https://github.com/scriptin/jmdict-simplified).
"""
