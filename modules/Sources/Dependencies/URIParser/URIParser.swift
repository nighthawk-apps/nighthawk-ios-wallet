//
//  URIParser.swift
//  stealth
//
//  Created by Lukáš Korba on 17.05.2022.
//

import Foundation
import DerivationTool
import Models

public struct QRCodeParseResult: Equatable {
    public let memo: String?
    public let amount: String?
    public var address: String
    public var contactInvite: NighthawkContact?

    public static var failed: Self {
        Self(memo: nil, amount: nil, address: "", contactInvite: nil)
    }

    public init(
        memo: String?,
        amount: String?,
        address: String,
        contactInvite: NighthawkContact? = nil
    ) {
        self.memo = memo
        self.amount = amount
        self.address = address
        self.contactInvite = contactInvite
    }
}

public struct URIParser {
    func parseZaddrOrZIP321(from qrCode: String, network: String) -> QRCodeParseResult {
        _ = network
        let trimmed = qrCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasPrefix("nighthawk://contact"),
           let contact = NighthawkContacts.parseInvite(trimmed) {
            return QRCodeParseResult(
                memo: nil,
                amount: nil,
                address: contact.walletAddress ?? "",
                contactInvite: contact
            )
        }
        guard lower.hasPrefix("drk:") || lower.hasPrefix("darkfi:") else {
            return .failed
        }
        guard let parsed = PaymentRequestUri.parse(trimmed), !parsed.address.isEmpty else {
            return .failed
        }
        return QRCodeParseResult(memo: parsed.memo, amount: parsed.amount, address: parsed.address)
    }
}
