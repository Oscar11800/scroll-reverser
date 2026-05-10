// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScrollReverser",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ScrollReverser",
            path: "Sources/ScrollReverser",
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        )
    ]
)
