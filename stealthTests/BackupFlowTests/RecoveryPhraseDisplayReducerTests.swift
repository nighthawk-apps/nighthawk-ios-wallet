// MARK: - DISABLED during DarkFi migration (removed Zcash module dependency)
// Original file preserved. Re-enable after porting to DarkFi architecture.
//
// //
// //  RecoveryPhraseDisplayStoreTests.swift
// //  stealthTests
// //
// //  Created by Francisco Gindre on 12/8/21.
// //
// 
// import XCTest
// import ComposableArchitecture
// import Pasteboard
// import Models
// import RecoveryPhraseDisplay
// @testable import stealth_testnet
// 
// class RecoveryPhraseDisplayReducerTests: XCTestCase {    
//     func testNewPhrase() {
//         let store = TestStore(
//             initialState: RecoveryPhraseDisplayStore.empty,
//             reducer: RecoveryPhraseDisplayReducer()
//         )
//                 
//         store.send(.phraseResponse(.placeholder)) { state in
//             state.phrase = .placeholder
//             state.showCopyToBufferAlert = false
//         }
//     }
// }
// 
// private extension RecoveryPhraseDisplayStore {
//     static let test = RecoveryPhraseDisplayReducer.State(
//         phrase: .placeholder,
//         showCopyToBufferAlert: false
//     )
//     
//     static let empty = RecoveryPhraseDisplayReducer.State(
//         phrase: .empty,
//         showCopyToBufferAlert: false
//     )
// }
