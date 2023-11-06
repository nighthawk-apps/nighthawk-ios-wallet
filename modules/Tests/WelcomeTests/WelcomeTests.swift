//
//  WelcomeTests.swift
//
//
//  Created by Matthew Watt on 10/26/23.
//

import ComposableArchitecture
import XCTest
@testable import Welcome

@MainActor
class WelcomeTests: XCTestCase {
    func testCreateWallet() async {
        let store = TestStore(
            initialState: Welcome.State()
        ) {
            Welcome()
        }
        
        await store.send(.createNewWalletTapped)
        await store.receive(.delegate(.createNewWallet))
    }
    
    func testTermsAndConditionsTapped() {
        let store = TestStore(
            initialState: Welcome.State()
        ) {
            
        }
    }
}
