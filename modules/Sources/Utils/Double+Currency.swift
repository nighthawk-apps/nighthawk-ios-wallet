//
//  Double+Currency.swift
//

import Foundation

extension Double {
    public var currencyString: String {
        NumberFormatter.currencyFormatter.string(from: NSNumber(floatLiteral: self)) ?? ""
    }
}
