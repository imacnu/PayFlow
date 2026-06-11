// swift-tools-version: 6.0
// Paquete de lógica de negocio pura para Subscription Guardian.
// Solo depende de Foundation: sin SwiftUI, SwiftData ni UIKit.

import PackageDescription

let package = Package(
    name: "SubscriptionGuardianCore",
    platforms: [
        .iOS("26.0"),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SubscriptionGuardianCore",
            targets: ["SubscriptionGuardianCore"]
        )
    ],
    targets: [
        .target(
            name: "SubscriptionGuardianCore"
        ),
        .testTarget(
            name: "SubscriptionGuardianCoreTests",
            dependencies: ["SubscriptionGuardianCore"]
        )
    ]
)
