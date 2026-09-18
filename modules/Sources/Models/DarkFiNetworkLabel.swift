import Foundation

/// Compile-time DarkFi network for this binary (`stealth-mainnet` vs `stealth-testnet`).
public enum DarkFiNetworkLabel {
    public static var current: String {
        #if STEALTH_MAINNET
        "mainnet"
        #else
        "testnet"
        #endif
    }

    public static func isMainnet(_ networkType: String) -> Bool {
        networkType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "mainnet"
    }
}
