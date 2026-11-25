//
//  RecoveryPhraseDisplayReducerTests.swift
//  stealthTests
//
//  Tests for RecoveryPhraseDisplay including the onboarding 3-word backup quiz.
//

import ComposableArchitecture
import MnemonicClient
import Models
import RecoveryPhraseDisplay
import UserPreferencesStorage
import Utils
import WalletStorage
import XCTest

@MainActor
final class RecoveryPhraseDisplayReducerTests: XCTestCase {
    private let sampleWords = [
        "abandon", "ability", "able", "about", "above", "absent",
        "absorb", "abstract", "absurd", "abuse", "access", "accident",
        "account", "accuse", "achieve", "acid", "acoustic", "acquire",
        "across", "act", "action", "actor"
    ]

    func testPickVerificationWordsSelectsThreeSortedUniqueIndices() {
        let words = RecoveryPhraseDisplay.State.pickVerificationWords(from: sampleWords)
        XCTAssertEqual(words.count, 3)
        let indices = words.map(\.index)
        XCTAssertEqual(indices, indices.sorted())
        XCTAssertEqual(Set(indices).count, 3)
        for word in words {
            XCTAssertGreaterThanOrEqual(word.index, 1)
            XCTAssertLessThanOrEqual(word.index, sampleWords.count)
            XCTAssertEqual(word.expectedWord, sampleWords[word.index - 1])
            XCTAssertFalse(word.isMatched)
        }
    }

    func testOnboardingContinueBlockedUntilCheckboxAndThreeQuizWordsMatch() async {
        var backupMarkedComplete = false
        var initial = RecoveryPhraseDisplay.State(flow: .onboarding)
        initial.phrase = RecoveryPhrase(words: sampleWords.map(\.redacted))
        initial.verificationWords = RecoveryPhraseDisplay.State.pickVerificationWords(
            from: sampleWords,
            indicesOverride: [0, 5, 21]
        )

        var prefs = UserPreferencesStorageClient.liveValue
        prefs.setIsUserBackupComplete = { backupMarkedComplete = $0 }

        let store = TestStore(
            initialState: initial,
            reducer: RecoveryPhraseDisplay.init
        ) {
            $0.userStoredPreferences = prefs
        }

        // Neither checkbox nor quiz words entered -> continue is blocked.
        XCTAssertFalse(store.state.canContinueOnboarding)
        await store.send(.continuePressed)
        XCTAssertFalse(backupMarkedComplete)

        // Checkbox checked, quiz still incomplete -> still blocked.
        await store.send(.binding(.set(\.isConfirmSeedPhraseWrittenChecked, true))) {
            $0.isConfirmSeedPhraseWrittenChecked = true
        }
        XCTAssertFalse(store.state.canContinueOnboarding)
        await store.send(.continuePressed)
        XCTAssertFalse(backupMarkedComplete)

        // Enter wrong word for #1 -> still blocked.
        await store.send(.verificationWordChanged(index: 1, value: "wrong")) {
            $0.verificationWords[0].enteredWord = "wrong"
        }
        XCTAssertFalse(store.state.isQuizPassed)
        XCTAssertFalse(store.state.canContinueOnboarding)

        // Enter all 3 matching words (case- and whitespace-insensitive).
        await store.send(.verificationWordChanged(index: 1, value: " ABANDON ")) {
            $0.verificationWords[0].enteredWord = " ABANDON "
        }
        await store.send(.verificationWordChanged(index: 6, value: "absent")) {
            $0.verificationWords[1].enteredWord = "absent"
        }
        await store.send(.verificationWordChanged(index: 22, value: "Actor")) {
            $0.verificationWords[2].enteredWord = "Actor"
        }

        XCTAssertTrue(store.state.isQuizPassed)
        XCTAssertTrue(store.state.canContinueOnboarding)

        await store.send(.continuePressed)
        await store.receive(.delegate(.initializeSDKAndLaunchWallet))
        XCTAssertTrue(backupMarkedComplete)
    }

    func testOnAppearPopulatesQuizOnlyForOnboardingFlow() async {
        let phraseString = sampleWords.joined(separator: " ")
        var storage = WalletStorageClient.noOp
        storage.exportWallet = {
            StoredWallet(
                language: .english,
                seedPhrase: SeedPhrase(phraseString),
                version: 1,
                birthday: Birthday(42)
            )
        }
        var mnemonicClient = MnemonicClient.mock
        mnemonicClient.asWords = { $0.components(separatedBy: " ") }

        let onboardingStore = TestStore(
            initialState: RecoveryPhraseDisplay.State(flow: .onboarding),
            reducer: RecoveryPhraseDisplay.init
        ) {
            $0.walletStorage = storage
            $0.mnemonic = mnemonicClient
        }
        onboardingStore.exhaustivity = .off
        await onboardingStore.send(.onAppear)
        XCTAssertEqual(onboardingStore.state.phrase.words.count, 22)
        XCTAssertEqual(onboardingStore.state.birthday, 42)
        XCTAssertEqual(onboardingStore.state.verificationWords.count, 3)

        let settingsStore = TestStore(
            initialState: RecoveryPhraseDisplay.State(flow: .settings),
            reducer: RecoveryPhraseDisplay.init
        ) {
            $0.walletStorage = storage
            $0.mnemonic = mnemonicClient
        }
        await settingsStore.send(.onAppear) {
            $0.phrase = RecoveryPhrase(words: self.sampleWords.map(\.redacted))
            $0.birthday = 42
        }
        XCTAssertTrue(settingsStore.state.verificationWords.isEmpty)
    }
}
