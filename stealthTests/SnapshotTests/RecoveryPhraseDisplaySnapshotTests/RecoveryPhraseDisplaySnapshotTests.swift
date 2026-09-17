// MARK: - DISABLED during DarkFi migration (removed Zcash module dependency)
// Original file preserved. Re-enable after porting to DarkFi architecture.
//
// //
// //  RecoveryPhraseDisplaySnapshotTests.swift
// //  stealthTests
// //
//
// import XCTest
// import ComposableArchitecture
// import RecoveryPhraseDisplay
// @testable import stealth_testnet
//
// class RecoveryPhraseDisplaySnapshotTests: XCTestCase {
//     func testRecoveryPhraseDisplaySnapshot() throws {
//         let store = RecoveryPhraseDisplayStore(
//             initialState: .init(phrase: .placeholder),
//             reducer: RecoveryPhraseDisplayReducer.demo,
//             environment: Void()
//         )
//
//         addAttachments(RecoveryPhraseDisplayView(store: store))
//     }
// }
