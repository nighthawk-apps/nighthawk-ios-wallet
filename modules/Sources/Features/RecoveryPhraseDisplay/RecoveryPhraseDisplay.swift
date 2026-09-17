//
//  RecoveryPhraseDisplay.swift
//  stealth
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
        public var isOpeningWallet = false

        public init(flow: RecoveryPhraseDisplayFlow) {
            self.flow = flow
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case continuePressed
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case exportAsPdfPressed
        case onAppear

        public enum Delegate: Equatable {
            case showOnboardingCarousel
            case initializeSDKAndLaunchWallet
        }
    }

    @Reducer(state: .equatable, action: .equatable)
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
                guard state.flow == .onboarding,
                      state.isConfirmSeedPhraseWrittenChecked,
                      !state.isOpeningWallet
                else {
                    return .none
                }
                userStoredPreferences.setIsUserBackupComplete(true)
                state.isOpeningWallet = true
                if !userStoredPreferences.hasCompletedOnboarding() {
                    return .send(.delegate(.showOnboardingCarousel))
                }
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
                    return .none
                } catch {
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    public init() {}
}
