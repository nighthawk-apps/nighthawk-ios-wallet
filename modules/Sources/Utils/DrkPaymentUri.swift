import Foundation

/// `drk:<address>?amount=&memo=` invoices. Single-address wallets reuse the same receive address.
public enum DrkPaymentUri {
    public static func encode(address: String, amount: String?, memo: String?) -> String? {
        let addr = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !addr.isEmpty, addr.count <= 256 else { return nil }
        guard addr.unicodeScalars.allSatisfy({
            !CharacterSet.whitespacesAndNewlines.contains($0) && !CharacterSet.controlCharacters.contains($0)
        }) else {
            return nil
        }
        var query: [String] = []
        if let amount, !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query.append("amount=\(amount.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if let memo {
            let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                guard trimmed.utf8.count <= 255 else { return nil }
                let b64 = Data(trimmed.utf8).base64EncodedString()
                query.append("memo=\(b64)")
            }
        }
        var uri = "drk:\(addr)"
        if !query.isEmpty {
            uri += "?" + query.joined(separator: "&")
        }
        return uri
    }

    public static func parse(_ raw: String) -> (address: String, amount: String?, memo: String?)? {
        let stripped = raw.replacingOccurrences(of: " ", with: "")
        guard let schemeRange = stripped.range(of: "drk:", options: [.caseInsensitive]) else {
            return nil
        }
        let afterScheme = String(stripped[schemeRange.upperBound...])
        let parts = afterScheme.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let address = String(parts[0]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !address.isEmpty, address.count <= 256 else { return nil }

        var amount: String?
        var memo: String?
        if parts.count == 2 {
            let query = String(parts[1])
            for item in query.split(separator: "&") {
                let kv = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard kv.count == 2 else { continue }
                let key = kv[0].lowercased()
                let value = String(kv[1])
                if key == "amount" {
                    amount = value
                } else if key == "memo", let data = Data(base64Encoded: value),
                          let decoded = String(data: data, encoding: .utf8),
                          decoded.utf8.count <= 255 {
                    memo = decoded
                }
            }
        }
        return (address, amount, memo)
    }
}
