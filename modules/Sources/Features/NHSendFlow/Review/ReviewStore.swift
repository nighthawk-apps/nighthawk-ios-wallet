//
//  ReviewStore.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import Generated
import UIKit
import Utils
import ZcashLightClientKit

public typealias ReviewStore = Store<ReviewReducer.State, ReviewReducer.Action>
public typealias ReviewViewStore = ViewStore<ReviewReducer.State, ReviewReducer.Action>

public struct ReviewReducer: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        
        public var amount: Zatoshi
        public var memo: RedactableString
        public var recipient: RedactableString
        
        public init(
            amount: Zatoshi,
            memo: RedactableString,
            recipient: RedactableString
        ) {
            self.amount = amount
            self.memo = memo
            self.recipient = recipient
        }
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case alert(PresentationAction<Action>)
        case warnBeforeLeavingApp(URL?)
        case openBlockExplorer(URL?)
    }
    
    public init() {}
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            case .alert(.presented(let action)):
                return EffectTask(value: action)

            case .alert(.dismiss):
                state.alert = nil
                return .none

            case .alert:
                return .none
            case .warnBeforeLeavingApp(let blockExplorerURL):
                state.alert = AlertState.warnBeforeLeavingApp(blockExplorerURL)
                return .none
            case .openBlockExplorer(let blockExplorerURL):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            }
        }
    }
}

// MARK: Alerts

extension AlertState where Action == ReviewReducer.Action {
    public static func warnBeforeLeavingApp(_ blockExplorerURL: URL?) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWallet)
        } actions: {
            ButtonState(action: .openBlockExplorer(blockExplorerURL)) {
                TextState(L10n.Nighthawk.TransactionDetails.viewTxDetails)
            }
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWarning(blockExplorerURL?.host() ?? ""))
        }
    }
}
