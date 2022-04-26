// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.49.0"),
        .package(url: "https://github.com/uber/mockolo.git", from: "1.1.2"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
