//
//  URIParser.swift
//  stealth
//

import Foundation
import DerivationTool
import Utils

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
    func parseDrkPaymentUri(from qrCode: String, network: String) -> QRCodeParseResult {
        guard let parsed = DrkPaymentUri.parse(qrCode) else { return .failed }
        return QRCodeParseResult(memo: parsed.memo, amount: parsed.amount, address: parsed.address)
    }
}
