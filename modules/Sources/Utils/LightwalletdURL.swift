import Foundation

/// Resolves the lightwalletd URL from custom settings, Info.plist / xcconfig,
/// or (testnet only) the Studio ngrok fallback. Never invents a mainnet host.
public enum LightwalletdURL {
    public static let infoPlistKey = "LIGHTWALLETD_URL"

    /// Studio testnet last-resort only. Not used on mainnet.
    public static let testnetNgrokFallback =
        "https://epidermis-sandbox-marshland.ngrok-free.dev"

    public struct Parts: Equatable {
        public var scheme: String?
        public var host: String
        public var port: Int?
    }

    public static func configuredDefault(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String? {
        let candidates = [
            bundle.object(forInfoDictionaryKey: infoPlistKey) as? String,
            environment[infoPlistKey]
        ]
        for raw in candidates {
            guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !trimmed.isEmpty,
                  !trimmed.hasPrefix("$(")
            else { continue }
            return trimmed
        }
        return nil
    }

    public static func resolve(storedCustom: String?) throws -> String {
        if let storedCustom {
            let trimmed = storedCustom.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        if let configured = configuredDefault() {
            return configured
        }
        #if STEALTH_MAINNET
        throw DarkfiError(
            message: "No lightwalletd URL configured. Add a custom server under Settings → Change Server."
        )
        #else
        return testnetNgrokFallback
        #endif
    }

    public static func parse(_ raw: String) -> Parts? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        if lower.hasPrefix("https://") || lower.hasPrefix("http://") {
            guard let url = URL(string: trimmed), let host = url.host, !host.isEmpty else {
                return nil
            }
            return Parts(scheme: url.scheme?.lowercased(), host: host, port: url.port)
        }
        if lower.hasPrefix("tcp://") || lower.hasPrefix("tcp+tls://") || lower.hasPrefix("socks5://") {
            guard let url = URL(string: trimmed), let host = url.host, !host.isEmpty else {
                return nil
            }
            return Parts(scheme: url.scheme?.lowercased(), host: host, port: url.port)
        }
        guard let match = trimmed.wholeMatch(of: hostPortRegex) else { return nil }
        let host = String(match.output.1)
        guard let port = Int(match.output.2), (1...65535).contains(port) else { return nil }
        return Parts(scheme: nil, host: host, port: port)
    }

    private static let hostPortRegex = #/^((?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])(?:\.(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]))*):(\d{1,5})$/#
}
