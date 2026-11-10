import Foundation

/// `drk:` payment invoice (ZIP-321). Amount and memo are optional query items.
/// Memo is UTF-8 then standard base64 in the query item.
public enum PaymentRequestUri {
    public struct Parsed: Equatable {
        public let address: String
        public let amount: String?
        public let memo: String?

        public init(address: String, amount: String? = nil, memo: String? = nil) {
            self.address = address
            self.amount = amount
            self.memo = memo
        }
    }

    public static func build(address: String, amount: String?, memo: String?) -> String {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = ["drk:\(cleanAddress)"]
        var query: [String] = []
        if let amount = amount?.trimmingCharacters(in: .whitespacesAndNewlines), !amount.isEmpty {
            query.append("amount=\(percentEncode(amount))")
        }
        if let memo = memo?.trimmingCharacters(in: .whitespacesAndNewlines), !memo.isEmpty {
            let data = Data(memo.utf8)
            let b64 = data.base64EncodedString()
            query.append("memo=\(percentEncode(b64))")
        }
        if !query.isEmpty {
            parts.append("?")
            parts.append(query.joined(separator: "&"))
        }
        return parts.joined()
    }

    public static func parse(_ raw: String) -> Parsed? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        let withoutScheme: String
        if input.lowercased().hasPrefix("drk:") {
            withoutScheme = String(input.dropFirst(4))
        } else if input.lowercased().hasPrefix("darkfi:") {
            withoutScheme = String(input.dropFirst(7))
        } else {
            // Bare address candidate
            return Parsed(address: input)
        }

        let clean = withoutScheme.hasPrefix("//") ? String(withoutScheme.dropFirst(2)) : withoutScheme
        let parts = clean.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let address = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return nil }

        var amount: String? = nil
        var memo: String? = nil

        if parts.count > 1 {
            let queryString = String(parts[1])
            let pairs = queryString.split(separator: "&")
            for pair in pairs {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = String(kv[0]).lowercased()
                let val = kv.count > 1 ? String(kv[1]) : ""
                let decodedVal = val.removingPercentEncoding ?? val

                if key == "amount" && !decodedVal.isEmpty {
                    amount = decodedVal
                } else if key == "memo" && !decodedVal.isEmpty {
                    // Try base64 decoding first
                    if let data = Data(base64Encoded: decodedVal),
                       let text = String(data: data, encoding: .utf8),
                       !text.isEmpty {
                        memo = text
                    } else {
                        // Fallback to plain percent-decoded text
                        memo = decodedVal
                    }
                }
            }
        }

        return Parsed(address: address, amount: amount, memo: memo)
    }

    private static func percentEncode(_ value: String) -> String {
        // RFC 3986 unreserved only. Base64 uses '+', '/', and '=', which query
        // parsers treat as spaces or separators when they are left raw.
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
