// MARK: - DISABLED during DarkFi migration (removed Zcash module dependency)
// Original file preserved. Re-enable after porting to DarkFi architecture.
//
// //
// //  TransactionSendingSnapshotTests.swift
// //  stealthTests
// //
//
// import XCTest
// import ComposableArchitecture
// import SwiftUI
// import SendFlow
// import UIComponents
// @testable import stealth_testnet
//
// class TransactionSendingTests: XCTestCase {
//     func testTransactionSendingSnapshot() throws {
//         var state = SendFlowReducer.State.placeholder
//         state.addMemoState = true
//         state.transactionAddressInputState = TransactionAddressTextFieldReducer.State(
//             textFieldState: TCATextFieldReducer.State(
//                 validationType: nil,
//                 text: "ztestmockeddestinationaddress".redacted
//             )
//         )
//         state.transactionAmountInputState = TransactionAmountTextFieldReducer.State(
//             currencySelectionState: CurrencySelectionReducer.State(),
//             textFieldState: TCATextFieldReducer.State(
//                 validationType: nil,
//                 text: "2.91".redacted
//             )
//         )
//
//         let store = Store(
//             initialState: state,
//             reducer: SendFlowReducer(networkType: .testnet)
//                 .dependency(\.derivationTool, .live())
//                 .dependency(\.mainQueue, DispatchQueue.main.eraseToAnyScheduler())
//                 .dependency(\.numberFormatter, .live())
//                 .dependency(\.walletStorage, .live())
//                 .dependency(\.sdkSynchronizer, .mock)
//         )
//
//         ViewStore(store).send(.onAppear)
//         addAttachments(TransactionSendingView(viewStore: ViewStore(store), tokenName: "ZEC"))
//     }
// }
