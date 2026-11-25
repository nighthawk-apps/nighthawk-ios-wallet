//
//  ImportWalletTests.swift
//  stealthTests
//
//  Tests for DarkFi ImportWallet reducer (22-word mnemonic & optional birthday).
//

import ComposableArchitecture
import ImportWallet
import MnemonicClient
import UserPreferencesStorage
import Utils
import WalletStorage
import XCTest

@MainActor
final class ImportWalletTests: XCTestCase {
    private let valid22Words = Array(repeating: "abandon", count: 22).joined(separator: " ")

    func testInitialStateUsesDarkFi22WordCount() {
        let state = ImportWallet.State()
        XCTAssertEqual(state.maxWordsCount, DarkfiSeedPhrase.wordCount)
        XCTAssertEqual(state.maxWordsCount, 22)
        XCTAssertFalse(state.isValidMnemonic)
        XCTAssertTrue(state.isValidBirthday)
        XCTAssertFalse(state.isValidForm)
    }

    func testBindingValidatesMnemonicAndFormatsExtraWhitespace() async {
        var mnemonicClient = MnemonicClient.mock
        mnemonicClient.isValid = { phrase in
            phrase.split(separator: " ").count == 22
        }

        let store = TestStore(
            initialState: ImportWallet.State(),
            reducer: ImportWallet.init
        ) {
            $0.mnemonic = mnemonicClient
        }

        await store.send(.binding(.set(\.importedSeedPhrase, "one two three"))) {
            $0.importedSeedPhrase = "one two three"
            $0.mnemonicIsValid = false
        }
        XCTAssertFalse(store.state.isValidForm)

        let padded = "  \(valid22Words)  "
        await store.send(.binding(.set(\.importedSeedPhrase, padded))) {
            $0.importedSeedPhrase = padded
            $0.mnemonicIsValid = true
        }
        XCTAssertEqual(store.state.formattedPhrase, valid22Words)
        XCTAssertTrue(store.state.isValidForm)
    }

    func testContinueTappedImportsWalletAndMarksBackupComplete() async {
        var importedPhrase: String?
        var importedBirthday: BlockHeight?
        var backupCompleted = false

        let storage = WalletStorageClient(
            importWallet: { phrase, birthday, _ in
                importedPhrase = phrase
                importedBirthday = birthday
            },
            exportWallet: { .placeholder },
            areKeysPresent: { false },
            areLegacyKeysPresent: { false },
            exportLegacyPhrase: { "" },
            exportLegacyBirthday: { .zero },
            updateBirthday: { _ in },
            deleteWallet: {},
            deleteLegacyWallet: {}
        )

        var prefs = UserPreferencesStorageClient.liveValue
        prefs.setIsUserBackupComplete = { backupCompleted = $0 }

        var initial = ImportWallet.State()
        initial.importedSeedPhrase = valid22Words
        initial.birthdayHeight = "91808"
        initial.mnemonicIsValid = true

        let store = TestStore(
            initialState: initial,
            reducer: ImportWallet.init
        ) {
            $0.walletStorage = storage
            $0.userStoredPreferences = prefs
        }

        await store.send(.continueTapped)
        await store.receive(.delegate(.showImportSuccess))

        XCTAssertEqual(importedPhrase, valid22Words)
        XCTAssertEqual(importedBirthday, 91_808)
        XCTAssertTrue(backupCompleted)
    }
}
