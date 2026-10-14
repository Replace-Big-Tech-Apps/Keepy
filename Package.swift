// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Keepy",
    platforms: [.macOS("15.0")],
    targets: [
        .executableTarget(name: "Keepy", path: "Sources/Keepy")
    ]
)
