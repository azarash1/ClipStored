// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipStored",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipStored", targets: ["ClipStored"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ClipStored",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "Collections", package: "swift-collections")
            ]
        )
    ]
) 