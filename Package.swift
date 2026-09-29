// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-1035-coder",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 1035 Coder",
            targets: ["RFC 1035 Coder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Parser", "Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-binary.git", branch: "main", traits: ["Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cursor.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-parser.git", branch: "main", traits: ["Append", "IteratorLeaves", "Map", "Product", "Skip"]),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-1035.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 1035 Coder",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "RFC 1035", package: "swift-rfc-1035"),
                .product(name: "Serializer", package: "swift-serializer"),
            ]
        ),
        .testTarget(
            name: "RFC 1035 Coder Tests",
            dependencies: [
                "RFC 1035 Coder",
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "RFC 1035", package: "swift-rfc-1035"),
                .product(name: "Serializer", package: "swift-serializer"),
                .product(name: "Binary", package: "swift-binary"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
