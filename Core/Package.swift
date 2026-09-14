// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DonkeyKongCore",
    platforms: [.macOS(.v14), .iOS("26.0")],  // string form: `.v26` needs a newer tools-version
    products: [.library(name: "DonkeyKongCore", targets: ["DonkeyKongCore"])],
    targets: [
        .target(name: "DonkeyKongCore"),
        .testTarget(name: "DonkeyKongCoreTests", dependencies: ["DonkeyKongCore"]),
    ]
)
