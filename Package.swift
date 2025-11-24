// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "rzclipboard",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "rzclipboard",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ])
    ]
)
