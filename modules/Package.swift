// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "modules",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
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
        .library(name: "FiatPriceClient", targets: ["FiatPriceClient"]),
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
        .library(name: "ProcessInfoClient", targets: ["ProcessInfoClient"]),
        .library(name: "Receive", targets: ["Receive"]),
        .library(name: "RecoveryPhraseDisplay", targets: ["RecoveryPhraseDisplay"]),
        .library(name: "SDKSynchronizer", targets: ["SDKSynchronizer"]),
        .library(name: "SecItem", targets: ["SecItem"]),
        .library(name: "SubsonicClient", targets: ["SubsonicClient"]),
        .library(name: "SendFlow", targets: ["SendFlow"]),
        .library(name: "Splash", targets: ["Splash"]),
        .library(name: "TopUp", targets: ["TopUp"]),
        .library(name: "WalletCreated", targets: ["WalletCreated"]),
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
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.3.2"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.16.1"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", exact: "6.6.2"),
        .package(url: "https://github.com/Electric-Coin-Company/zcash-swift-wallet-sdk", exact: "2.2.7"),
        .package(url: "https://github.com/zcash-hackworks/MnemonicSwift", exact: "2.2.4"),
        .package(url: "https://github.com/twostraws/Subsonic", exact: "0.2.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: "4.3.0"),
        .package(url: "https://github.com/elai950/AlertToast.git", revision: "638f38f9daf08e17b7caea22d2fcb9c0a418d1b6"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", revision: "d108a1fa6189e661f91560548ef48651ed8d93b9"),
        .package(url: "https://github.com/unstoppabledomains/resolution-swift", exact: "5.2.1")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "UserPreferencesStorage",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
            name: "FiatPriceClient",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/FiatPriceClient"
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "FiatPriceClient",
                "FileManager",
                "Models",
                "TransactionDetail",
                "UserPreferencesStorage",
                "ProcessInfoClient",
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "UserPreferencesStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "Generated",
                "Utils",
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
            name: "ProcessInfoClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/ProcessInfoClient"
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "UserPreferencesStorage",
                "Utils",
                "WalletStorage",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                "ProcessInfoClient",
                "UserPreferencesStorage",
                "UIComponents",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk")
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk"),
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
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk"),
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
                "UserPreferencesStorage",
                .product(name: "ZcashLightClientKit", package: "zcash-swift-wallet-sdk"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/ZcashSDKEnvironment"
        )
    ]
)
