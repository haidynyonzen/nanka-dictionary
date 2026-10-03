# nanka-dictionary

The dictionary database used by the Nanka Japanese dictionary app, and the Swift tool that builds it.

- **Download the database:** see [Releases](https://github.com/haidynyonzen/nanka-dictionary/releases). Each release has `dictionary.sqlite.zip`, a SQLite file with FTS5 search indexes.
- **Build it yourself:** `swift run -c release DictionaryBuilder` (macOS 26+, Swift 6.2). It downloads the pinned source files into `cache/`, checks their SHA-256 hashes, and writes `build/dictionary.sqlite` in about 15 seconds. Pass `--output <path>` to write somewhere else, or `--fixture` for a small test database.

## Contents
| Part | What it is | Licence |
|---|---|---|
| `Sources/DictionaryCore` | Schema SQL and kana normalization shared with apps that read the database | MIT |
| `Sources/DictionaryBuilder` | Command-line tool: JMdict / KANJIDIC2 JSON → SQLite | MIT |
| `dictionary.sqlite` (release asset) | The built database | CC BY-SA 4.0 (see [LICENSE-DATA](LICENSE-DATA)) |

## Data sources and attribution
The database uses the [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html) and [KANJIDIC2](https://www.edrdg.org/wiki/index.php/KANJIDIC_Project) dictionary files. These files are the property of the [Electronic Dictionary Research and Development Group](https://www.edrdg.org/) (EDRDG), and are used in conformity with the Group's [licence](https://www.edrdg.org/edrdg/licence.html), [Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

The files were converted to JSON by [jmdict-simplified](https://github.com/scriptin/jmdict-simplified). The exact release and file hashes are pinned in `Sources/DictionaryBuilder/SourceInfo.swift`, and stored in each database's `meta` table.

Word JLPT levels come from Jonathan Waller's [JLPT Resources](http://www.tanos.co.uk/jlpt/), licensed [Creative Commons Attribution](https://creativecommons.org/licenses/by/4.0/), as matched to JMdict entries by [yomitan-jlpt-vocab](https://github.com/stephenmk/yomitan-jlpt-vocab), licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Only its data files are used (pinned by commit and SHA-256 in `SourceInfo.swift`), not its code. There have been no official JLPT word lists since 2010, so these levels are an informed estimate.

No copyright is claimed on the dictionary data. It is provided as-is, without warranty of any kind.

## Changes made to the source data
The built database is an adaptation of JMdict (English glosses) and KANJIDIC2, licensed under CC BY-SA 4.0. Compared with the source files it:
- reorganizes the data into SQLite tables (`entry`, `kanji_form`, `reading`, `sense`, `kanji`, `tag`, `meta`),
- adds a `search_key` table of normalized forms (katakana and half-width kana folded to hiragana, full-width Latin narrowed and lowercased), a `gloss_fts` full-text index for English search (rowids ordered by priority, then gloss length, so `LIMIT n` yields good candidates), and a pre-ranked `gloss_exact` table for exact English lookups,
- keeps only English glosses and meanings,
- picks a headword per entry, never using a search-only (`sK`) kanji form: いらっしゃる is shown in kana rather than as 居らっしゃる,
- adds a JLPT level per entry (`entry.jlpt`, 5 = N5) and gives easier levels a small ranking bonus in `entry.priority`, so everyday words come before formal synonyms (本 before 書籍),
- keeps, from KANJIDIC2, the literal, grade, stroke count, JLPT level, frequency, on/kun readings, nanori, English meanings and classical radical. It leaves out the fields under KANJIDIC2's special conditions (SKIP, pinyin, Four Corner, Morohashi, Spahn/Hadamitzky, Korean readings, De Roo).

JLPT levels in KANJIDIC2 (on `kanji`) follow the old four-level test and are unofficial. Word levels (on `entry`) use the current N5–N1 scale.
