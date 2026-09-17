//
//  TransactionAddressTextFieldTests.swift
//  stealthTests
//

import XCTest
import ComposableArchitecture
import UIComponents
@testable import stealth_testnet

class TransactionAddressTextFieldTests: XCTestCase {
    func testClearValue() throws {
        let store = TestStore(
            initialState:
                TransactionAddressTextFieldReducer.State(
                    textFieldState:
                        TCATextFieldReducer.State(
                            validationType: nil,
                            text: "t1gXqfSSQt6WfpwyuCU3Wi7sSVZ66DYQ3Po".redacted
                        )
                ),
            reducer: TransactionAddressTextFieldReducer(networkType: .testnet)
        )

        store.send(.clearAddress) { state in
            state.textFieldState.text = "".redacted
        }
    }
}
