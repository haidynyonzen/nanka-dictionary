// swift-tools-version: 6.2
import PackageDescription

// Builds the Nanka dictionary database from JMdict / KANJIDIC2, and shares its schema with apps that read it.
let package = Package(
    name: "nanka-dictionary",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "DictionaryCore", targets: ["DictionaryCore"]),
        .executable(name: "DictionaryBuilder", targets: ["DictionaryBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
    ],
    targets: [
        // Schema SQL and kana normalization. No dependencies, so any app can use it.
        .target(name: "DictionaryCore"),
        .executableTarget(
            name: "DictionaryBuilder",
            dependencies: ["DictionaryCore", .product(name: "GRDB", package: "GRDB.swift")]
        ),
        .testTarget(name: "DictionaryCoreTests", dependencies: ["DictionaryCore"]),
    ]
)
