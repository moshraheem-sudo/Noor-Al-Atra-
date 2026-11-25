// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "noor_ios_bridge",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "noor-ios-bridge",
            targets: ["noor_ios_bridge"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "noor_ios_bridge",
            dependencies: [],
            path: "Classes",
            sources: ["NoorIosBridgePlugin.swift"]
        )
    ]
)
