// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExportKit",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "ExportKit",
            targets: ["ExportKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ExportKit",
            dependencies: []),
    ]
)
