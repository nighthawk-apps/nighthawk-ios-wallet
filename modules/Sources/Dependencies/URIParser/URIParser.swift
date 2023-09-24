//
//  URIParser.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 17.05.2022.
//

import Foundation
import ZcashLightClientKit
import DerivationTool

public struct QRCodeParseResult: Equatable {
    public let memo: String?
    public let amount: String?
    public var address: String
    
    public static var failed: Self {
        Self(memo: nil, amount: nil, address: "")
    }
    
    public init(memo: String?, amount: String?, address: String) {
        self.memo = memo
        self.amount = amount
        self.address = address
    }
}

public struct URIParser {
    func parseZaddrOrZIP321(from qrCode: String, network: NetworkType) -> QRCodeParseResult {
        let stripped = qrCode.replacingOccurrences(of: " ", with: "")
        let nsRange = NSRange(location: 0, length: stripped.utf8.count)
        var amount: String?
        var zaddr: String?
        var memo: String?
        
        let shieldedPrefix = switch network {
        case .mainnet:
            "zs"
        case .testnet:
            "ztestsapling"
        }
        
        guard
            let zaddrRegex = try? NSRegularExpression(pattern: "(\(shieldedPrefix)\\w{76})"),
            let uriRegex = try? NSRegularExpression(pattern: "(zcash:\(shieldedPrefix)\\w{76})"),
            let memoRegex = try? NSRegularExpression(pattern: "(memo=([^&]*))"),
            let amountRegex = try? NSRegularExpression(pattern: "(amount=([^&]*))")
        else { return .failed }
        
        let zAddrMatch = zaddrRegex.firstMatch(in: stripped, range: nsRange)
        let uriMatch = uriRegex.firstMatch(in: stripped, range: nsRange)
        guard zAddrMatch != nil || uriMatch != nil else { return .failed }
        
        if let zAddrMatch, let range = Range(zAddrMatch.range, in: stripped) {
            zaddr = String(stripped[range])
        }
        
        if let memoMatch = memoRegex.firstMatch(in: stripped, range: nsRange),
           let range = Range(memoMatch.range(at: 2), in: stripped),
           let data = Data(base64Encoded: String(stripped[range])) {
            memo = String(data: data, encoding: .utf8)
        }
        
        if let amountMatch = amountRegex.firstMatch(in: stripped, range: nsRange), let range = Range(amountMatch.range(at: 2), in: stripped) {
            amount = String(stripped[range])
        }
        
        return QRCodeParseResult(memo: memo, amount: amount, address: zaddr ?? "")
    }
}
