import CryptoKit
import Foundation

enum DownloadError: Error, CustomStringConvertible {
    case badStatus(Int)
    case checksumMismatch(file: String, expected: String, actual: String)
    case tarFailed(Int32)

    var description: String {
        switch self {
        case .badStatus(let code): "download failed with HTTP status \(code)"
        case .checksumMismatch(let file, let expected, let actual):
            "checksum mismatch for \(file)\n  expected \(expected)\n  actual   \(actual)"
        case .tarFailed(let code): "tar exited with status \(code)"
        }
    }
}

/// Downloads, verifies and unpacks the pinned source files into the cache folder.
struct SourceFetcher {
    let cacheDirectory: URL

    /// Returns the URL of the extracted JSON file, downloading only when needed.
    func fetchJSON(_ source: SourceFile) async throws -> URL {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let archive = cacheDirectory.appendingPathComponent(source.assetName)
        let json = cacheDirectory.appendingPathComponent(source.jsonName)

        if !isValidArchive(archive, sha256: source.sha256) {
            try await download(source, to: archive)
        }
        // The archive is checksum-verified, so an existing JSON next to it is trusted.
        if !FileManager.default.fileExists(atPath: json.path) {
            try extract(archive)
        }
        return json
    }

    // MARK: - Private

    private func isValidArchive(_ url: URL, sha256 expected: String) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return Self.sha256Hex(of: data) == expected
    }

    private func download(_ source: SourceFile, to destination: URL) async throws {
        print("Downloading \(source.assetName) ...")
        // The "+" in the asset name must be percent-encoded in the URL.
        let encoded = source.assetName.replacingOccurrences(of: "+", with: "%2B")
        let (data, response) = try await URLSession.shared.data(from: URL(string: PinnedSources.baseURL + encoded)!)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw DownloadError.badStatus(http.statusCode)
        }
        let actual = Self.sha256Hex(of: data)
        guard actual == source.sha256 else {
            throw DownloadError.checksumMismatch(file: source.assetName, expected: source.sha256, actual: actual)
        }
        try data.write(to: destination)
    }

    private func extract(_ archive: URL) throws {
        print("Extracting \(archive.lastPathComponent) ...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xzf", archive.path, "-C", cacheDirectory.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw DownloadError.tarFailed(process.terminationStatus) }
    }

    private static func sha256Hex(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
