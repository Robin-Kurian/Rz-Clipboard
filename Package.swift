// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "R-ClipHistory",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "R-ClipHistory",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ])
    ]
)
