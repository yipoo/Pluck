// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Snap", targets: ["Snap"])
    ],
    dependencies: [
        // W2 添加:.package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        // W5 添加:.package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
        // W6 添加:.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        // W7 添加:.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "Snap",
            dependencies: [
                // W2:"HotKey",
                // W5:.product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/Snap"
        ),
        .testTarget(
            name: "SnapTests",
            dependencies: ["Snap"],
            path: "Tests/SnapTests"
        )
    ]
)
