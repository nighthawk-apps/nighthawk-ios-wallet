//
//  WalletStorageTests.swift
//  stealthTests
//
//  Created by Lukáš Korba on 10.03.2022.
//

import Models
import Utils
import WalletStorage
import XCTest

extension WalletStorage.WalletStorageError {
    var debugValue: String {
        switch self {
        case .alreadyImported: return "alreadyImported"
        case .uninitializedWallet: return "uninitializedWallet"
        case .storageError: return "storageError"
        case .unsupportedVersion: return "unsupportedVersion"
        case .unsupportedLanguage: return "unsupportedLanguage"
        }
    }
}

final class WalletStorageTests: XCTestCase {
    let birthday = BlockHeight(12_345_678)
    let seedPhrase = "one two three"
    let language = MnemonicLanguageType.english
    var storage = WalletStorage(secItem: .live)

    override func setUp() {
        super.setUp()
        storage.darkfiStoredWalletPrefix = "test_walletStorage_"
        deleteData(forKey: WalletStorage.Constants.darkfiStoredWallet)
    }

    override func tearDown() {
        deleteData(forKey: WalletStorage.Constants.darkfiStoredWallet)
        super.tearDown()
    }

    func testWalletStoredSuccessfully() throws {
        try storage.importWallet(bip39: seedPhrase, birthday: birthday)
        guard let data = data(forKey: WalletStorage.Constants.darkfiStoredWallet) else {
            return XCTFail("Keychain: no data found for key: `darkfiStoredWallet`.")
        }

        guard let walletReceived = try storage.decode(json: data, as: StoredWallet.self) else {
            return XCTFail("Keychain: `walletReceived` can't be decoded.")
        }

        XCTAssertEqual(birthday, walletReceived.birthday?.value())
        XCTAssertEqual(seedPhrase, walletReceived.seedPhrase.value())
    }

    func testWalletDuplicate() throws {
        do {
            try storage.importWallet(bip39: seedPhrase, birthday: birthday)
            try storage.importWallet(bip39: seedPhrase, birthday: birthday)

            XCTFail("Keychain: expected duplicate error.")
        } catch {
            guard let error = error as? WalletStorage.WalletStorageError else {
                XCTFail("Keychain: expected WalletStorageError but got \(error).")
                return
            }

            XCTAssertEqual(
                error.debugValue,
                WalletStorage.WalletStorageError.alreadyImported.debugValue
            )
        }
    }

    func testUninitializedWallet() throws {
        do {
            _ = try storage.exportWallet()

            XCTFail("Keychain: `testUninitializedWallet` should fail.")
        } catch {
            guard let error = error as? WalletStorage.WalletStorageError else {
                return XCTFail("Keychain: expected WalletStorageError but got \(error).")
            }

            XCTAssertEqual(
                error.debugValue,
                WalletStorage.WalletStorageError.uninitializedWallet.debugValue
            )
        }
    }

    func testDeleteWallet() throws {
        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(seedPhrase),
            version: WalletStorage.Constants.darkfiKeychainVersion,
            birthday: Birthday(birthday)
        )

        guard let walletData = try storage.encode(object: wallet) else {
            return XCTFail("`testDeleteWallet` encoding `walletData` failed.")
        }

        try setData(walletData, forKey: WalletStorage.Constants.darkfiStoredWallet)
        storage.deleteWallet()

        let stored = data(forKey: WalletStorage.Constants.darkfiStoredWallet)
        XCTAssertNil(stored)
    }

    func testUpdateBirthdayOverNil() throws {
        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(seedPhrase),
            version: WalletStorage.Constants.darkfiKeychainVersion,
            birthday: nil
        )

        guard let walletData = try storage.encode(object: wallet) else {
            return XCTFail("`testUpdateBirthdayOverNil` encoding `walletData` failed.")
        }

        try setData(walletData, forKey: WalletStorage.Constants.darkfiStoredWallet)
        try storage.updateBirthday(birthday)

        guard let stored = data(forKey: WalletStorage.Constants.darkfiStoredWallet),
              let walletReceived = try storage.decode(json: stored, as: StoredWallet.self) else {
            return XCTFail("Keychain: failed to read updated wallet.")
        }

        XCTAssertEqual(birthday, walletReceived.birthday?.value())
        XCTAssertEqual(seedPhrase, walletReceived.seedPhrase.value())
    }

    func testUpdateBirthdayOverSomeBirthday() throws {
        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(seedPhrase),
            version: WalletStorage.Constants.darkfiKeychainVersion,
            birthday: Birthday(birthday)
        )
        let newBirthday = BlockHeight(87_654_321)

        guard let walletData = try storage.encode(object: wallet) else {
            return XCTFail("`testUpdateBirthdayOverSomeBirthday` encoding failed.")
        }

        try setData(walletData, forKey: WalletStorage.Constants.darkfiStoredWallet)
        try storage.updateBirthday(newBirthday)

        guard let stored = data(forKey: WalletStorage.Constants.darkfiStoredWallet),
              let walletReceived = try storage.decode(json: stored, as: StoredWallet.self) else {
            return XCTFail("Keychain: failed to read updated wallet.")
        }

        XCTAssertEqual(newBirthday, walletReceived.birthday?.value())
        XCTAssertEqual(seedPhrase, walletReceived.seedPhrase.value())
    }

    func testUnsupportedVersion() throws {
        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(seedPhrase),
            version: WalletStorage.Constants.darkfiKeychainVersion - 1,
            birthday: Birthday(birthday)
        )

        guard let walletData = try storage.encode(object: wallet) else {
            return XCTFail("`testUnsupportedVersion` encoding failed.")
        }

        try setData(walletData, forKey: WalletStorage.Constants.darkfiStoredWallet)

        do {
            _ = try storage.exportWallet()
            XCTFail("Keychain: `testUnsupportedVersion` should fail.")
        } catch WalletStorage.WalletStorageError.unsupportedVersion(let version) {
            XCTAssertEqual(version + 1, WalletStorage.Constants.darkfiKeychainVersion)
        } catch {
            XCTFail("Keychain: expected `unsupportedVersion` error but threw \(error).")
        }
    }

    func testUnsupportedLanguage() throws {
        do {
            try storage.importWallet(bip39: seedPhrase, birthday: birthday, language: .chinese)
            XCTFail("Keychain: `testUnsupportedLanguage` should fail.")
        } catch WalletStorage.WalletStorageError.unsupportedLanguage(let languageToStore) {
            XCTAssertEqual(MnemonicLanguageType.chinese, languageToStore)
        } catch {
            XCTFail("Keychain: expected `unsupportedLanguage` error but threw \(error).")
        }
    }
    func testLegacyMnemonicLanguageTypeJsonRoundTrip() throws {
        // Legacy MnemonicSwift.MnemonicLanguageType encoded `.english` as `{"english":{}}`.
        let legacyJson = Data(#"{"english":{}}"#.utf8)
        let decoded = try JSONDecoder().decode(MnemonicLanguageType.self, from: legacyJson)
        XCTAssertEqual(decoded, .english)

        let reencoded = try JSONEncoder().encode(decoded)
        let reparsed = try JSONDecoder().decode(MnemonicLanguageType.self, from: reencoded)
        XCTAssertEqual(reparsed, .english)
    }
}

// MARK: - Misc

private extension WalletStorageTests {
    func setData(
        account: String = "",
        _ data: Data,
        forKey: String
    ) throws {
        var query = storage.baseQuery(forAccount: account, andKey: forKey)
        query[kSecValueData as String] = data as AnyObject
        SecItemAdd(query as CFDictionary, nil)
    }

    func data(
        forKey: String,
        account: String = ""
    ) -> Data? {
        let query = storage.restoreQuery(forAccount: account, andKey: forKey)
        var result: AnyObject?
        _ = SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    @discardableResult
    func deleteData(
        forKey: String,
        account: String = ""
    ) -> Bool {
        let query = storage.baseQuery(forAccount: account, andKey: forKey)
        let status = SecItemDelete(query as CFDictionary)
        return status == noErr
    }
}
