//
//  AdvancedStore.swift
//  
//
//  Created by Matthew Watt on 8/3/23.
//

import ComposableArchitecture
import Generated
import Models
import NHUserPreferencesStorage

public typealias AdvancedStore = Store<AdvancedReducer.State, AdvancedReducer.Action>
public typealias AdvancedViewStore = ViewStore<AdvancedReducer.State, AdvancedReducer.Action>

public struct AdvancedReducer: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        
        @BindingState public var selectedScreenMode: NighthawkSetting.ScreenMode?
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Action>)
        case binding(BindingAction<State>)
        case nukeWalletRequested
        case nukeWalletConfirmed
        case onAppear
    }
    
    public init() {}
    
    @Dependency(\.nhUserStoredPreferences) var nhUserStoredPreferences
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.presented(let action)):
                return EffectTask(value: action)
            case .alert(.dismiss):
                state.alert = nil
                return .none
            case .nukeWalletRequested:
                state.alert = AlertState.warnBeforeNukingWallet
                return .none
            case .onAppear:
                state.selectedScreenMode = nhUserStoredPreferences.screenMode()
                return .none
            case .alert, .binding, .nukeWalletConfirmed:
                return .none
            }
        }
    }
}

// MARK: Alerts
extension AlertState where Action == AdvancedReducer.Action {
    public static var warnBeforeNukingWallet: AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.lastWarningTitle)
        } actions: {
            ButtonState(role: .destructive, action: .nukeWalletConfirmed) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.title)
            }
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.lastWarningMessage)
        }
    }
}
