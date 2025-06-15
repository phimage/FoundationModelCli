// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FM",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "fm", targets: ["FM"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.1"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.9.0"),
        .package(url: "https://github.com/phimage/MCPUtils.git", from: "0.0.3"),
    ],
    targets: [
        .executableTarget(
            name: "FM",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "MCPUtils", package: "MCPUtils"),
            ],
            path: "Sources/FM"
        )
    ]
)
