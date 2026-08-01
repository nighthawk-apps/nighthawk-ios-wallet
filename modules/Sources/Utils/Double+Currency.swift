//
//  Double+Currency.swift
//
//
//  Created by Matthew Watt on 10/3/23.
//

import Foundation

extension Double {
    public var currencyString: String {
        NumberFormatter.currencyFormatter.string(from: NSNumber(floatLiteral: self)) ?? ""
    }
}
