//
//  NHHomeStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture

struct NHHomeReducer: ReducerProtocol {
    struct State: Equatable {
        enum Destination: Equatable, Hashable {
            case wallet
            case transfer // todo: figma breaks this out into send and receive, but android is just transfer
            case settings
        }
        
        @BindingState var destination = Destination.wallet
        
        var wallet: WalletReducer.State
        var transfer: TransferReducer.State
        var settings: NHSettingsReducer.State
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case settings(NHSettingsReducer.Action)
        case transfer(TransferReducer.Action)
        case updateDestination(NHHomeReducer.State.Destination)
        case wallet(WalletReducer.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case .binding, .settings, .transfer, .wallet:
                return .none
            }
        }
    }
}

extension Store<NHHomeReducer.State, NHHomeReducer.Action> {
    func walletStore() -> Store<WalletReducer.State, WalletReducer.Action> {
        scope(state: \.wallet, action: Action.wallet)
    }
    
    func transferStore() -> Store<TransferReducer.State, TransferReducer.Action> {
        scope(state: \.transfer, action: Action.transfer)
    }
    
    func settingsStore() -> Store<NHSettingsReducer.State, NHSettingsReducer.Action> {
        scope(state: \.settings, action: Action.settings)
    }
}

// MARK: Placeholders
extension NHHomeReducer.State {
    static var placeholder: Self {
        .init(
            wallet: .placeholder,
            transfer: .placeholder,
            settings: .placeholder
        )
    }
}
