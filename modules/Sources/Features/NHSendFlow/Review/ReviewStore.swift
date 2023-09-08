//
//  ReviewStore.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import DerivationTool
import Generated
import Models
import UIKit
import Utils
import ZcashLightClientKit

public typealias ReviewStore = Store<ReviewReducer.State, ReviewReducer.Action>
public typealias ReviewViewStore = ViewStore<ReviewReducer.State, ReviewReducer.Action>

public struct ReviewReducer: ReducerProtocol {
    let networkType: NetworkType
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        
        public var subtotal: Zatoshi
        public var fee = Zatoshi(10_000) // TODO: [#1186] Show ZIP-317 fees when SDK supports it (https://github.com/zcash/ZcashLightClientKit/issues/1186)
        public var memo: RedactableString?
        public var recipient: RedactableString
        public var recipientIsTransparent = false
        public var total: Zatoshi { subtotal + fee }
        
        public init(
            subtotal: Zatoshi,
            memo: RedactableString?,
            recipient: RedactableString
        ) {
            self.subtotal = subtotal
            self.memo = memo
            self.recipient = recipient
        }
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case alert(PresentationAction<Action>)
        case warnBeforeLeavingApp(URL?)
        case onAppear
        case openBlockExplorer(URL?)
        case sendZcashTapped
    }
    
    @Dependency(\.derivationTool) var derivationTool
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
            case .onAppear:
                state.recipientIsTransparent = derivationTool.isTransparentAddress(state.recipient.data, networkType)
                return .none
            case .openBlockExplorer(let blockExplorerURL):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .sendZcashTapped:
                return .none
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
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
