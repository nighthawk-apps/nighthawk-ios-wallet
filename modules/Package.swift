// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "modules",
    platforms: [
      .iOS(.v16)
    ],
    products: [
        .library(name: "Addresses", targets: ["Addresses"]),
        .library(name: "App", targets: ["App"]),
        .library(name: "AppVersion", targets: ["AppVersion"]),
        .library(name: "AudioServices", targets: ["AudioServices"]),
        .library(name: "Autoshield", targets: ["Autoshield"]),
        .library(name: "CaptureDevice", targets: ["CaptureDevice"]),
        .library(name: "DatabaseFiles", targets: ["DatabaseFiles"]),
        .library(name: "Date", targets: ["Date"]),
        .library(name: "DerivationTool", targets: ["DerivationTool"]),
        .library(name: "DiskSpaceChecker", targets: ["DiskSpaceChecker"]),
        .library(name: "ExportSeed", targets: ["ExportSeed"]),
        .library(name: "FeedbackGenerator", targets: ["FeedbackGenerator"]),
        .library(name: "FileManager", targets: ["FileManager"]),
        .library(name: "Generated", targets: ["Generated"]),
        .library(name: "ImportWallet", targets: ["ImportWallet"]),
        .library(name: "ImportWalletSuccess", targets: ["ImportWalletSuccess"]),
        .library(name: "ImportWarning", targets: ["ImportWarning"]),
        .library(name: "Migrate", targets: ["Migrate"]),
        .library(name: "Home", targets: ["Home"]),
        .library(name: "TransactionDetail", targets: ["TransactionDetail"]),
        .library(name: "UserPreferencesStorage", targets: ["UserPreferencesStorage"]),
        .library(name: "LocalAuthenticationClient", targets: ["LocalAuthenticationClient"]),
        .library(name: "MnemonicClient", targets: ["MnemonicClient"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "NumberFormatter", targets: ["NumberFormatter"]),
        .library(name: "Partners", targets: ["Partners"]),
        .library(name: "Pasteboard", targets: ["Pasteboard"]),
        .library(name: "Receive", targets: ["Receive"]),
        .library(name: "RecoveryPhraseDisplay", targets: ["RecoveryPhraseDisplay"]),
        .library(name: "SDKSynchronizer", targets: ["SDKSynchronizer"]),
        .library(name: "SecItem", targets: ["SecItem"]),
        .library(name: "SubsonicClient", targets: ["SubsonicClient"]),
        .library(name: "SendFlow", targets: ["SendFlow"]),
        .library(name: "Splash", targets: ["Splash"]),
        .library(name: "TopUp", targets: ["TopUp"]),
        .library(name: "WalletCreated", targets: ["WalletCreated"]),
        .library(name: "SupportDataGenerator", targets: ["SupportDataGenerator"]),
        .library(name: "UNSClient", targets: ["UNSClient"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
        .library(name: "URIParser", targets: ["URIParser"]),
        .library(name: "UserDefaults", targets: ["UserDefaults"]),
        .library(name: "UserNotificationCenter", targets: ["UserNotificationCenter"]),
        .library(name: "Utils", targets: ["Utils"]),
        .library(name: "WalletStorage", targets: ["WalletStorage"]),
        .library(name: "Welcome", targets: ["Welcome"]),
        .library(name: "ZcashSDKEnvironment", targets: ["ZcashSDKEnvironment"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.2.0"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0"),
        .package(url: "https://github.com/zcash/ZcashLightClientKit", from: "2.0.0"),
        .package(url: "https://github.com/zcash-hackworks/MnemonicSwift", from: "2.2.4"),
        .package(url: "https://github.com/twostraws/Subsonic", from: "0.2.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.2.0"),
        .package(url: "https://github.com/elai950/AlertToast.git", branch: "master"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", revision: "d108a1fa6189e661f91560548ef48651ed8d93b9"),
        .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "5.2.1")
    ],
    targets: [
        .target(
            name: "Addresses",
            dependencies: [
                "Generated",
                "Pasteboard",
                "SDKSynchronizer",
                "UIComponents",
                "Utils",
                .product(name: "AlertToast", package: "AlertToast"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Addresses"
        ),
        .target(
            name: "App",
            dependencies: [
                "DerivationTool",
                "FileManager",
                "Home",
                "ImportWallet",
                "ImportWalletSuccess",
                "Migrate",
                "MnemonicClient",
                "Models",
                "RecoveryPhraseDisplay",
                "SDKSynchronizer",
                "Splash",
                "UserPreferencesStorage",
                "WalletCreated",
                "Welcome",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/App"
        ),
        .target(
            name: "AppVersion",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/AppVersion"
        ),
        .target(
            name: "AudioServices",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/AudioServices"
        ),
        .target(
            name: "Autoshield",
            dependencies: [
                "DerivationTool",
                "Generated",
                "MnemonicClient",
                "SDKSynchronizer",
                "UIComponents",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Autoshield"
        ),
        .target(
            name: "CaptureDevice",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/CaptureDevice"
        ),
        .target(
            name: "DatabaseFiles",
            dependencies: [
                "FileManager",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/DatabaseFiles"
        ),
        .target(
            name: "DataManager",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/DataManager"
        ),
        .target(
            name: "Date",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/Date"
        ),
        .target(
            name: "DerivationTool",
            dependencies: [
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/DerivationTool"
        ),
        .target(
            name: "DiskSpaceChecker",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/Dependencies/DiskSpaceChecker"
        ),
        .target(
            name: "ExportSeed",
            dependencies: [
                "MnemonicClient",
                "Models",
                "UIComponents",
                "WalletStorage",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/ExportSeed"
        ),
        .target(
            name: "FeedbackGenerator",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/FeedbackGenerator"
        ),
        .target(
            name: "FileManager",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/FileManager"
        ),
        .target(
            name: "Generated",
            resources: [.process("Resources")]
        ),
        .target(
            name: "ImportWallet",
            dependencies: [
                "Generated",
                "MnemonicClient",
                "UIComponents",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/ImportWallet"
        ),
        .target(
            name: "ImportWalletSuccess",
            dependencies: [
                "FeedbackGenerator",
                "Generated",
                "SubsonicClient",
                "UIComponents",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/ImportWalletSuccess"
        ),
        .target(
            name: "ImportWarning",
            dependencies: [
                "Generated",
                "UIComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/ImportWarning"
        ),
        .target(
            name: "Migrate",
            dependencies: [
                "Generated",
                "UIComponents",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/Migrate"
        ),
        .target(
            name: "Home",
            dependencies: [
                "Addresses",
                "AppVersion",
                "Autoshield",
                "DataManager",
                "Date",
                "DiskSpaceChecker",
                "FileManager",
                "Models",
                "TransactionDetail",
                "UserPreferencesStorage",
                "Receive",
                "RecoveryPhraseDisplay",
                "LocalAuthenticationClient",
                "SendFlow",
                "SDKSynchronizer",
                "TopUp",
                "UIComponents",
                "UserNotificationCenter",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Home"
        ),
        .target(
            name: "TransactionDetail",
            dependencies: [
                "Generated",
                "Models",
                "SDKSynchronizer",
                "UIComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/TransactionDetail"
        ),
        .target(
            name: "UserPreferencesStorage",
            dependencies: [
                "Models",
                "UserDefaults",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/UserPreferencesStorage"
        ),
        .target(
            name: "LocalAuthenticationClient",
            dependencies: [
                "Generated",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/LocalAuthenticationClient"
        ),
        .target(
            name: "MnemonicClient",
            dependencies: [
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/MnemonicClient"
        ),
        .target(
            name: "Models",
            dependencies: [
                "Utils",
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Models"
        ),
        .target(
            name: "NumberFormatter",
            dependencies: [
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/NumberFormatter"
        ),
        .target(
            name: "Partners",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/Partners"
        ),
        .target(
            name: "Pasteboard",
            dependencies: [
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/Pasteboard"
        ),
        .target(
            name: "Receive",
            dependencies: [
                "Generated",
                "Pasteboard",
                "SDKSynchronizer",
                "UIComponents",
                .product(name: "AlertToast", package: "AlertToast"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Receive"
        ),
        .target(
            name: "RecoveryPhraseDisplay",
            dependencies: [
                "ExportSeed",
                "Generated",
                "Models",
                "Pasteboard",
                "UIComponents",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/RecoveryPhraseDisplay"
        ),
        .target(
            name: "SDKSynchronizer",
            dependencies: [
                "DatabaseFiles",
                "Models",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/SDKSynchronizer"
        ),
        .target(
            name: "SecItem",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/SecItem"
        ),
        .target(
            name: "SubsonicClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Subsonic", package: "Subsonic")
            ],
            path: "Sources/Dependencies/SubsonicClient"
        ),
        .target(
            name: "SendFlow",
            dependencies: [
                "AudioServices",
                "CaptureDevice",
                "Generated",
                "DerivationTool",
                "MnemonicClient",
                "SDKSynchronizer",
                "UIComponents",
                "UNSClient",
                "URIParser",
                "Utils",
                "WalletStorage",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/SendFlow"
        ),
        .target(
            name: "Splash",
            dependencies: [
                "DatabaseFiles",
                "Generated",
                "LocalAuthenticationClient",
                "Models",
                "UserPreferencesStorage",
                "UIComponents",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Splash"
        ),
        .target(
            name: "TopUp",
            dependencies: [
                "Generated",
                "Partners",
                "Pasteboard",
                "SDKSynchronizer",
                "UIComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/TopUp"
        ),
        .target(
            name: "WalletCreated",
            dependencies: [
                "FeedbackGenerator",
                "Generated",
                "SubsonicClient",
                "UIComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/Features/WalletCreated"
        ),
        .target(
            name: "SupportDataGenerator",
            dependencies: [
                "Generated",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/SupportDataGenerator"
        ),
        .target(
            name: "UNSClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "UnstoppableDomainsResolution", package: "resolution-swift")
            ],
            path: "Sources/Dependencies/UNSClient"
        ),
        .target(
            name: "UIComponents",
            dependencies: [
                "DerivationTool",
                "Generated",
                "Models",
                "NumberFormatter",
                "Utils",
                "ZcashSDKEnvironment",
                .product(name: "AlertToast", package: "AlertToast")
            ],
            path: "Sources/UIComponents"
        ),
        .target(
            name: "URIParser",
            dependencies: [
                "DerivationTool",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/URIParser"
        ),
        .target(
            name: "UserDefaults",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/UserDefaults"
        ),
        .target(
            name: "UserNotificationCenter",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/UserNotificationCenter"
        ),
        .target(
            name: "Utils",
            dependencies: [
                "FileManager",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "Lottie", package: "lottie-spm")
            ],
            path: "Sources/Utils"
        ),
        .target(
            name: "WalletStorage",
            dependencies: [
                "Utils",
                "SecItem",
                "MnemonicClient",
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "KeychainSwift", package: "keychain-swift")
            ],
            path: "Sources/Dependencies/WalletStorage"
        ),
        .target(
            name: "Welcome",
            dependencies: [
                "Generated",
                "ImportWarning",
                "UIComponents",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/Welcome"
        ),
        .target(
            name: "ZcashSDKEnvironment",
            dependencies: [
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/ZcashSDKEnvironment"
        )
    ]
)
