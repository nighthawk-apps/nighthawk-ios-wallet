//
//  RecoveryPhraseDisplay.swift
//  stealth
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import ExportSeed
import Foundation
import MnemonicClient
import Models
import Pasteboard
import UserPreferencesStorage
import Utils
import WalletStorage

@Reducer
public struct RecoveryPhraseDisplay {
    public struct VerificationWord: Equatable, Identifiable {
        /// 1-based word position in the recovery phrase (e.g. 1...22).
        public let index: Int
        public let expectedWord: String
        public var enteredWord: String

        public var id: Int { index }

        public var isMatched: Bool {
            let expected = expectedWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let entered = enteredWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !expected.isEmpty && entered == expected
        }

        public init(index: Int, expectedWord: String, enteredWord: String = "") {
            self.index = index
            self.expectedWord = expectedWord
            self.enteredWord = enteredWord
        }
    }

    @ObservableState
    public struct State: Equatable {
        public enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }

        @Presents public var destination: Destination.State?
        public var flow: RecoveryPhraseDisplayFlow
        public var phrase: RecoveryPhrase = .empty
        public var birthday: BlockHeight = .zero
        public var isConfirmSeedPhraseWrittenChecked = false
        /// 3 randomly selected words the user must type to prove they backed up the seed during onboarding.
        public var verificationWords: [VerificationWord] = []

        public var isQuizPassed: Bool {
            !verificationWords.isEmpty && verificationWords.allSatisfy(\.isMatched)
        }

        public var canContinueOnboarding: Bool {
            guard flow == .onboarding, isConfirmSeedPhraseWrittenChecked else {
                return false
            }
            if phrase.words.count < 3 {
                return true
            }
            return isQuizPassed
        }

        public init(flow: RecoveryPhraseDisplayFlow) {
            self.flow = flow
        }

        public static func pickVerificationWords(
            from words: [String],
            count: Int = 3,
            indicesOverride: [Int]? = nil
        ) -> [VerificationWord] {
            guard words.count >= count, count > 0 else { return [] }
            let chosen: [Int]
            if let override = indicesOverride {
                chosen = override.filter { $0 >= 0 && $0 < words.count }.prefix(count).sorted()
            } else {
                chosen = Array(0..<words.count).shuffled().prefix(count).sorted()
            }
            return chosen.map { zeroBased in
                VerificationWord(index: zeroBased + 1, expectedWord: words[zeroBased])
            }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case continuePressed
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case exportAsPdfPressed
        case onAppear
        case verificationWordChanged(index: Int, value: String)

        public enum Delegate: Equatable {
            case initializeSDKAndLaunchWallet
        }
    }

    @Reducer
    public enum Destination {
        case exportSeedAlert(ExportSeed)
    }

    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .continuePressed:
                guard state.canContinueOnboarding else {
                    return .none
                }
                userStoredPreferences.setIsUserBackupComplete(true)
                return .send(.delegate(.initializeSDKAndLaunchWallet))
            case .delegate:
                return .none
            case .destination(.dismiss):
                return .none
            case .destination:
                return .none
            case .exportAsPdfPressed:
                state.destination = .exportSeedAlert(.init())
                return .none
            case .onAppear:
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let phraseWords = mnemonic.asWords(storedWallet.seedPhrase.value())
                    state.phrase = RecoveryPhrase(words: phraseWords.map { $0.redacted })
                    // DarkFi: no checkpoint concept
                    state.birthday = storedWallet.birthday?.value() ?? 0
                    if state.flow == .onboarding && state.verificationWords.isEmpty {
                        state.verificationWords = State.pickVerificationWords(from: phraseWords)
                    }
                    return .none
                } catch {
                    return .none
                }
            case let .verificationWordChanged(index, value):
                if let idx = state.verificationWords.firstIndex(where: { $0.index == index }) {
                    state.verificationWords[idx].enteredWord = value
                }
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    public init() {}
}

extension RecoveryPhraseDisplay.Destination.State: Equatable {}
extension RecoveryPhraseDisplay.Destination.Action: Equatable {}
