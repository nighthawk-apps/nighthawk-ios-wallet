import Foundation

/// Canonical DarkFi block-explorer URLs. Only `/tx/{id}` is published;
/// there is no `/address/` route — do not invent one.
public enum DarkFiExplorer {
    public static let mainnetBase = "https://explorer.dark.fi"
    public static let testnetBase = "https://explorer.testnet.dark.fi"

    public static func baseURL(networkType: String) -> String {
        DarkFiNetworkLabel.isMainnet(networkType) ? mainnetBase : testnetBase
    }

    public static func transactionURL(txid: String, networkType: String) -> URL? {
        guard let id = sanitizedPathComponent(txid) else { return nil }
        return URL(string: "\(baseURL(networkType: networkType))/tx/\(id)")
    }

    /// DarkFi explorers do not list receive addresses. Always `nil`.
    public static func recipientURL(address: String, networkType: String) -> URL? {
        _ = address
        _ = networkType
        return nil
    }

    static func sanitizedPathComponent(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains(where: { $0 == "/" || $0 == "?" || $0 == "#" || $0 == "\\" }) {
            return nil
        }
        return trimmed
    }
}
