//
//  WalletStorageKeychainQueryTests.swift
//  stealthTests
//
//  Create Wallet was failing with WalletStorageError.alreadyImported (NSError code 0)
//  because search/delete queries included kSecAttrAccessible.
//

import SecItem
import Security
import WalletStorage
import XCTest

final class WalletStorageKeychainQueryTests: XCTestCase {
    func testSearchQueryOmitsAccessibilityAttribute() {
        let storage = WalletStorage(secItem: .live)
        let query = storage.baseQuery(andKey: WalletStorage.Constants.darkfiStoredWallet)
        XCTAssertNil(query[kSecAttrAccessible as String])
        XCTAssertEqual(query[kSecClass as String] as? NSString, kSecClassGenericPassword)
        XCTAssertEqual(
            query[kSecAttrService as String] as? String,
            WalletStorage.Constants.darkfiStoredWallet
        )
    }

    func testImportWalletReplacesDuplicateKeychainItem() throws {
        var addCount = 0
        var updateCount = 0
        let secItem = SecItemClient(
            copyMatching: { _, _ in errSecSuccess },
            add: { _, _ in
                addCount += 1
                return errSecDuplicateItem
            },
            update: { _, _ in
                updateCount += 1
                return errSecSuccess
            },
            delete: { _ in errSecSuccess }
        )
        let storage = WalletStorage(secItem: secItem)
        try storage.importWallet(bip39: "one two three", birthday: 0)
        XCTAssertEqual(addCount, 1)
        XCTAssertEqual(updateCount, 1)
    }

    func testReplaceDataFallsBackToAddWhenUpdateMissesLeftover() throws {
        var addCount = 0
        var deleteCount = 0
        let secItem = SecItemClient(
            copyMatching: { _, _ in errSecSuccess },
            add: { _, _ in
                addCount += 1
                if addCount == 1 { return errSecDuplicateItem }
                return errSecSuccess
            },
            update: { _, _ in errSecItemNotFound },
            delete: { _ in
                deleteCount += 1
                return errSecSuccess
            }
        )
        let storage = WalletStorage(secItem: secItem)
        try storage.importWallet(bip39: "one two three", birthday: 0)
        XCTAssertGreaterThanOrEqual(addCount, 2)
        XCTAssertGreaterThanOrEqual(deleteCount, 2)
    }
}
