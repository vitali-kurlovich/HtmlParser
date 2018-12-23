// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HtmlParser",
    products: [
        .library(
            name: "HtmlParser",
            targets: ["HtmlParser"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "HtmlParser",
            dependencies: []),
        .testTarget(
            name: "HtmlParserTests",
            dependencies: ["HtmlParser"]),
    ]
)
