// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "LaskinWebAPI",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.1"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc.2"),
        
        // This is the package to add Leaf 🍁 support
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0-rc.2"),
        
        // This package is for authentication
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc.3.1")

    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", "Vapor", "Leaf", "Authentication"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
