// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IBUgramKit",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "IBUgramKit", targets: ["IBUgramKit"])
    ],
    targets: [
        .target(
            name: "IBUgramKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "IBUgramKitTests",
            dependencies: ["IBUgramKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
