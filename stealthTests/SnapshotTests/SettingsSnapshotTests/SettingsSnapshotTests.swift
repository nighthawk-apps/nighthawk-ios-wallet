// MARK: - DISABLED during DarkFi migration (removed Zcash module dependency)
// Original file preserved. Re-enable after porting to DarkFi architecture.
//
// //
// //  SettingsSnapshotTests.swift
// //  stealthTests
// //
// //  Created by Lukáš Korba on 21.07.2022.
// //
// 
// import XCTest
// import ComposableArchitecture
// import SwiftUI
// import Settings
// @testable import stealth_testnet
// 
// class SettingsSnapshotTests: XCTestCase {
//     func testSettingsSnapshot() throws {
//         let store = Store(
//             initialState: .placeholder,
//             reducer: SettingsReducer()
//                 .dependency(\.localAuthentication, .mockAuthenticationFailed)
//                 .dependency(\.sdkSynchronizer, .noOp)
//                 .dependency(\.walletStorage, .noOp)
//                 .dependency(\.appVersion, .mock)
//         )
//         
//         addAttachments(SettingsView(store: store))
//     }
//     
//     func testAboutSnapshot() throws {
//         let store = Store(
//             initialState: .placeholder,
//             reducer: SettingsReducer()
//                 .dependency(\.localAuthentication, .mockAuthenticationFailed)
//                 .dependency(\.sdkSynchronizer, .noOp)
//                 .dependency(\.walletStorage, .noOp)
//                 .dependency(\.appVersion, .liveValue)
//         )
//         
//         ViewStore(store).send(.onAppear)
//         addAttachments(About(store: store))
//     }
// }
