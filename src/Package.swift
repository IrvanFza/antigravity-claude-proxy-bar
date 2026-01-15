// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AntiGravityClaudeProxy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AntiGravityClaudeProxy", targets: ["AntiGravityClaudeProxy"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "AntiGravityClaudeProxy",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
