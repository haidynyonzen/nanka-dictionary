import Foundation

/// Parsed command-line flags.
struct Options {
    var output: URL
    var isFixture = false
    var cacheDirectory: URL

    static let defaultRelativePath = "build/dictionary.sqlite"
    static let fixtureRelativePath = "build/fixture.sqlite"

    /// Usage: `--output <path>`, `--fixture`.
    static func parse(_ arguments: [String]) throws -> Options {
        let root = try repositoryRoot()
        var explicitOutput: URL?
        var options = Options(
            output: root.appendingPathComponent(defaultRelativePath),
            cacheDirectory: root.appendingPathComponent("cache")
        )
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--output":
                guard let path = iterator.next() else { throw OptionsError.missingValue("--output") }
                // Relative to where the command was run, which is what a user typing a path expects.
                explicitOutput = URL(fileURLWithPath: path).standardizedFileURL
            case "--fixture": options.isFixture = true
            default: throw OptionsError.unknownFlag(argument)
            }
        }
        if options.isFixture { options.output = root.appendingPathComponent(fixtureRelativePath) }
        if let explicitOutput { options.output = explicitOutput }
        return options
    }

    /// The repo root is the nearest parent of the working directory that holds Package.swift.
    private static func repositoryRoot() throws -> URL {
        var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        while directory.path != "/" {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("Package.swift").path) {
                return directory
            }
            directory.deleteLastPathComponent()
        }
        throw OptionsError.repositoryRootNotFound
    }
}

enum OptionsError: Error, CustomStringConvertible {
    case missingValue(String)
    case unknownFlag(String)
    case repositoryRootNotFound

    var description: String {
        switch self {
        case .missingValue(let flag): "\(flag) needs a value"
        case .unknownFlag(let flag): "unknown flag \(flag). Usage: --output <path> | --fixture"
        case .repositoryRootNotFound: "run from inside the repository (Package.swift not found in any parent folder)"
        }
    }
}
