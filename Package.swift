// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "VNote",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VNote", targets: ["VNote"])
    ],
    targets: [
        .executableTarget(
            name: "VNote",
            path: "Sources/VNote"
        ),
        .testTarget(
            name: "VNoteTests",
            dependencies: ["VNote"],
            path: "Tests/VNoteTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
