import ComposableArchitecture
import ZcashLightClientKit
import DatabaseFiles
import Deeplink
import RecoveryPhraseValidationFlow
import ZcashSDKEnvironment
import WalletStorage
import WalletConfigProvider
import UserPreferencesStorage
import Models
import RecoveryPhraseDisplay
import Welcome
import Generated
import Foundation
import ExportLogs
import OnboardingFlow
import Sandbox
import Home

public typealias RootStore = Store<RootReducer.State, RootReducer.Action>
public typealias RootViewStore = ViewStore<RootReducer.State, RootReducer.Action>

public struct RootReducer: ReducerProtocol {
    enum CancelId { case timer }
    enum SynchronizerCancelId { case timer }
    enum WalletConfigCancelId { case timer }
    let tokenName: String
    let zcashNetwork: ZcashNetwork

    struct State: Equatable {
        @PresentationState var alert: AlertState<Action>?
        var appInitializationState: InitializationState = .uninitialized
        var debugState: DebugState
        var destinationState: DestinationState
        var exportLogsState: ExportLogsReducer.State
        var nhHomeState: NHHomeReducer.State
        var homeState: HomeReducer.State
        var onboardingState: OnboardingFlowReducer.State
        var phraseValidationState: RecoveryPhraseValidationFlowReducer.State
        var phraseDisplayState: RecoveryPhraseDisplayReducer.State
        var sandboxState: SandboxReducer.State
        var storedWallet: StoredWallet?
        var walletConfig: WalletConfig
        var welcomeState: WelcomeReducer.State
    }

    public enum Action: Equatable {
        case alert(PresentationAction<Action>)
        case binding(BindingAction<RootReducer.State>)
        case debug(DebugAction)
        case destination(DestinationAction)
        case exportLogs(ExportLogsReducer.Action)
        case nhHome(NHHomeReducer.Action)
        case home(HomeReducer.Action)
        case initialization(InitializationAction)
        case nukeWalletFailed
        case nukeWalletSucceeded
        case onboarding(OnboardingFlowReducer.Action)
        case phraseDisplay(RecoveryPhraseDisplayReducer.Action)
        case phraseValidation(RecoveryPhraseValidationFlowReducer.Action)
        case sandbox(SandboxReducer.Action)
        case updateStateAfterConfigUpdate(WalletConfig)
        case walletConfigLoaded(WalletConfig)
        case welcome(WelcomeReducer.Action)
    }

    // TODO: [#747] crashReporter needs a bit of extra work, see https://github.com/zcash/secant-ios-wallet/issues/747
    //@Dependency(\.crashReporter) var crashReporter
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.deeplink) var deeplink
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.randomRecoveryPhrase) var randomRecoveryPhrase
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletConfigProvider) var walletConfigProvider
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment

    public init(tokenName: String, zcashNetwork: ZcashNetwork) {
        self.tokenName = tokenName
        self.zcashNetwork = zcashNetwork
    }
    
    @ReducerBuilder<State, Action>
    var core: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Scope(state: \.nhHomeState, action: /Action.nhHome) {
            NHHomeReducer()
        }

        Scope(state: \.homeState, action: /Action.home) {
            HomeReducer(networkType: zcashNetwork.networkType)
        }

        Scope(state: \.exportLogsState, action: /Action.exportLogs) {
            ExportLogsReducer()
        }

        Scope(state: \.onboardingState, action: /Action.onboarding) {
            OnboardingFlowReducer(saplingActivationHeight: zcashNetwork.constants.saplingActivationHeight)
        }

        Scope(state: \.phraseValidationState, action: /Action.phraseValidation) {
            RecoveryPhraseValidationFlowReducer()
        }

        Scope(state: \.phraseDisplayState, action: /Action.phraseDisplay) {
            RecoveryPhraseDisplayReducer()
        }

        Scope(state: \.sandboxState, action: /Action.sandbox) {
            SandboxReducer()
        }

        Scope(state: \.welcomeState, action: /Action.welcome) {
            WelcomeReducer()
        }

        initializationReduce()

        destinationReduce()
        
        debugReduce()
    }
    
    public var body: some ReducerProtocol<State, Action> {
        self.core
    }
}

extension RootReducer {
    public static func walletInitializationState(
        databaseFiles: DatabaseFilesClient,
        walletStorage: WalletStorageClient,
        zcashNetwork: ZcashNetwork
    ) -> InitializationState {
        var keysPresent = false
        do {
            keysPresent = try walletStorage.areKeysPresent()
            let databaseFilesPresent = databaseFiles.areDbFilesPresentFor(
                zcashNetwork
            )
            
            switch (keysPresent, databaseFilesPresent) {
            case (false, false):
                return .uninitialized
            case (false, true):
                return .keysMissing
            case (true, false):
                return .filesMissing
            case (true, true):
                return .initialized
            }
        } catch WalletStorage.WalletStorageError.uninitializedWallet {
            if databaseFiles.areDbFilesPresentFor(zcashNetwork) {
                return .keysMissing
            }
        } catch {
            return .failed
        }
        
        return .uninitialized
    }
}

// MARK: Alerts

extension AlertState where Action == RootReducer.Action {
    public static func cantCreateNewWallet(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Root.Initialization.Alert.CantCreateNewWallet.message(error.message, error.code.rawValue))
        }
    }
    
    public static func cantLoadSeedPhrase() -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Root.Initialization.Alert.CantLoadSeedPhrase.message)
        }
    }
    
    public static func cantStartSync(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Debug.Alert.Rewind.CantStartSync.title)
        } message: {
            TextState(L10n.Root.Debug.Alert.Rewind.CantStartSync.message(error.message, error.code.rawValue))
        }
    }
    
    public static func cantStoreThatUserPassedPhraseBackupTest(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.Failed.title)
        } message: {
            TextState(
                L10n.Root.Initialization.Alert.CantStoreThatUserPassedPhraseBackupTest.message(error.message, error.code.rawValue)
            )
        }
    }
    
    public static func failedToProcessDeeplink(_ url: URL, _ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Destination.Alert.FailedToProcessDeeplink.title)
        } message: {
            TextState(L10n.Root.Destination.Alert.FailedToProcessDeeplink.message(url, error.message, error.code.rawValue))
        }
    }
    
    public static func initializationFailed(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.SdkInitFailed.title)
        } message: {
            TextState(L10n.Root.Initialization.Alert.Error.message(error.message, error.code.rawValue))
        }
    }
    
    public static func rewindFailed(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Root.Debug.Alert.Rewind.Failed.title)
        } message: {
            TextState(L10n.Root.Debug.Alert.Rewind.Failed.message(error.message, error.code.rawValue))
        }
    }
    
    public static func walletStateFailed(_ walletState: InitializationState) -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Root.Initialization.Alert.WalletStateFailed.message(walletState))
        }
    }
    
    public static func wipeFailed() -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.WipeFailed.title)
        }
    }
    
    public static func wipeRequest() -> AlertState {
        AlertState {
            TextState(L10n.Root.Initialization.Alert.Wipe.title)
        } actions: {
            ButtonState(role: .destructive, action: .initialization(.nukeWallet)) {
                TextState(L10n.General.yes)
            }
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
                TextState(L10n.General.no)
            }
        } message: {
            TextState(L10n.Root.Initialization.Alert.Wipe.message)
        }
    }
}

// MARK: Placeholders

extension RootReducer.State {
    public static var placeholder: Self {
        .init(
            debugState: .placeholder,
            destinationState: .placeholder,
            exportLogsState: .placeholder,
            nhHomeState: .placeholder,
            homeState: .placeholder,
            onboardingState: .init(
                walletConfig: .default,
                importWalletState: .placeholder,
                nhImportWalletState: .placeholder,
                walletCreatedState: .placeholder
            ),
            phraseValidationState: .placeholder,
            phraseDisplayState: RecoveryPhraseDisplayReducer.State(
                flow: .settings,
                phrase: .placeholder
            ),
            sandboxState: .placeholder,
            walletConfig: .default,
            welcomeState: .placeholder
        )
    }
}

extension RootStore {
    public static var placeholder: RootStore {
        RootStore(
            initialState: .placeholder,
            reducer: RootReducer(
                tokenName: "ZEC",
                zcashNetwork: ZcashNetworkBuilder.network(for: .testnet)
            ).logging()
        )
    }
}
